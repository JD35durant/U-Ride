-- ============================================================================
-- U-RIDE — SCHÉMA POSTGRESQL & SUPABASE (Cahier des charges v1.0)
-- Plateforme de covoiturage étudiant — Université de Saint-Boniface, Winnipeg
-- ============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. PROFILS ÉTUDIANTS (F-01, F-02, F-03)
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    student_id_number VARCHAR(30) UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(150) NOT NULL,
    faculty VARCHAR(150) NOT NULL,
    phone_number VARCHAR(25),
    home_zone VARCHAR(100) NOT NULL, -- Saint-Vital, Downtown, Fort Garry, St. Norbert, etc.
    preferred_schedule TEXT,
    avatar_url TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMPTZ,
    rating_avg NUMERIC(3, 2) DEFAULT 5.00,
    rating_count INT DEFAULT 0,
    trips_completed INT DEFAULT 0,
    car_model VARCHAR(100),
    car_color VARCHAR(50),
    car_plate VARCHAR(30),
    car_seats INT DEFAULT 4,
    pref_music BOOLEAN DEFAULT TRUE,
    pref_chat BOOLEAN DEFAULT TRUE,
    pref_smoking BOOLEAN DEFAULT FALSE, -- Strict non-fumeur
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. TRAJETS CONDUCTEURS (F-04)
CREATE TYPE trip_direction_enum AS ENUM ('to_usb', 'from_usb');
CREATE TYPE ride_status_enum AS ENUM ('active', 'completed', 'cancelled');

CREATE TABLE public.rides (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    origin_zone VARCHAR(100) NOT NULL,
    pickup_details TEXT NOT NULL,
    destination VARCHAR(255) NOT NULL DEFAULT 'Université de Saint-Boniface (200 Av. de la Cathédrale)',
    direction trip_direction_enum DEFAULT 'to_usb',
    departure_time TIME NOT NULL,
    estimated_arrival_time TIME NOT NULL,
    is_recurring BOOLEAN DEFAULT TRUE,
    recurring_days VARCHAR(10)[] DEFAULT ARRAY['Lun', 'Mer', 'Ven'], -- Array of days
    single_date DATE,
    total_seats INT NOT NULL CHECK (total_seats BETWEEN 1 AND 6),
    available_seats INT NOT NULL CHECK (available_seats >= 0),
    suggested_price NUMERIC(5, 2) NOT NULL DEFAULT 3.50,
    notes TEXT,
    status ride_status_enum DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. RÉSERVATIONS & DEMANDES DE PLACE (F-07)
CREATE TYPE booking_status_enum AS ENUM ('pending', 'confirmed', 'rejected', 'cancelled', 'completed');

CREATE TABLE public.bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ride_id UUID NOT NULL REFERENCES public.rides(id) ON DELETE CASCADE,
    passenger_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status booking_status_enum DEFAULT 'pending',
    pickup_note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (ride_id, passenger_id)
);

-- 5. CONVERSATIONS & MESSAGERIE (F-08)
CREATE TABLE public.conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ride_id UUID NOT NULL REFERENCES public.rides(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL REFERENCES public.profiles(id),
    passenger_id UUID NOT NULL REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (ride_id, passenger_id)
);

CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id),
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. ÉVALUATIONS & RÉPUTATION (F-09)
CREATE TABLE public.reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ride_id UUID NOT NULL REFERENCES public.rides(id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL REFERENCES public.profiles(id),
    reviewee_id UUID NOT NULL REFERENCES public.profiles(id),
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. FONCTION DE CALCUL SMARTMATCH (F-06)
CREATE OR REPLACE FUNCTION calculate_smartmatch(
    p_ride_id UUID,
    p_passenger_zone VARCHAR(100),
    p_preferred_hour TIME,
    p_day VARCHAR(10)
) RETURNS INT AS $$
DECLARE
    r RECORD;
    v_score INT := 50;
BEGIN
    SELECT * INTO r FROM public.rides WHERE id = p_ride_id;
    IF NOT FOUND THEN RETURN 0; END IF;

    -- Zone match (+30%)
    IF LOWER(r.origin_zone) = LOWER(p_passenger_zone) THEN
        v_score := v_score + 30;
    ELSIF (p_passenger_zone = 'Saint-Vital' AND r.origin_zone = 'St. Norbert') THEN
        v_score := v_score + 15;
    END IF;

    -- Day match (+10%)
    IF p_day = ANY(r.recurring_days) THEN
        v_score := v_score + 10;
    END IF;

    -- Time alignment (+10%)
    IF ABS(EXTRACT(EPOCH FROM (r.departure_time - p_preferred_hour)) / 60) <= 30 THEN
        v_score := v_score + 10;
    END IF;

    IF v_score > 98 THEN v_score := 98; END IF;
    RETURN v_score;
END;
$$ LANGUAGE plpgsql;

-- 8. TRIGGER POUR DÉCRÉMENTER LES PLACES SUR CONFIRMATION
CREATE OR REPLACE FUNCTION handle_booking_seats()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT' AND NEW.status = 'confirmed') OR
       (TG_OP = 'UPDATE' AND OLD.status != 'confirmed' AND NEW.status = 'confirmed') THEN
        UPDATE public.rides
        SET available_seats = GREATEST(0, available_seats - 1)
        WHERE id = NEW.ride_id;
    ELSIF (TG_OP = 'UPDATE' AND OLD.status = 'confirmed' AND (NEW.status = 'cancelled' OR NEW.status = 'rejected')) THEN
        UPDATE public.rides
        SET available_seats = available_seats + 1
        WHERE id = NEW.ride_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_manage_booking_seats
AFTER INSERT OR UPDATE ON public.bookings
FOR EACH ROW EXECUTE FUNCTION handle_booking_seats();

-- 9. POLITIQUES DE SÉCURITÉ ROW LEVEL SECURITY (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- Lecture publique pour les étudiants authentifiés
CREATE POLICY "Profiles are readable by authenticated users" ON public.profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Rides are readable by authenticated users" ON public.rides FOR SELECT TO authenticated USING (true);

-- Modification de ses propres ressources
CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Drivers can insert rides" ON public.rides FOR INSERT WITH CHECK (auth.uid() = driver_id);
CREATE POLICY "Drivers can update their rides" ON public.rides FOR UPDATE USING (auth.uid() = driver_id);

-- Réservations
CREATE POLICY "Passengers can see their bookings" ON public.bookings FOR SELECT USING (auth.uid() = passenger_id OR auth.uid() IN (SELECT driver_id FROM public.rides WHERE id = ride_id));
CREATE POLICY "Passengers can insert bookings" ON public.bookings FOR INSERT WITH CHECK (auth.uid() = passenger_id);
CREATE POLICY "Participants can update booking status" ON public.bookings FOR UPDATE USING (auth.uid() = passenger_id OR auth.uid() IN (SELECT driver_id FROM public.rides WHERE id = ride_id));

-- Messages
CREATE POLICY "Participants can view messages" ON public.messages FOR SELECT USING (
    auth.uid() IN (SELECT driver_id FROM public.conversations WHERE id = conversation_id) OR
    auth.uid() IN (SELECT passenger_id FROM public.conversations WHERE id = conversation_id)
);
CREATE POLICY "Participants can insert messages" ON public.messages FOR INSERT WITH CHECK (
    auth.uid() = sender_id AND (
        auth.uid() IN (SELECT driver_id FROM public.conversations WHERE id = conversation_id) OR
        auth.uid() IN (SELECT passenger_id FROM public.conversations WHERE id = conversation_id)
    )
);
