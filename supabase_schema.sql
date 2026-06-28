-- SQL Schema for Career Copilot Database
-- Create the schemas, tables, and enable Row Level Security (RLS)

-- Profiles table extending user authentication details
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    full_name TEXT,
    email TEXT,
    target_role TEXT DEFAULT 'Software Engineer',
    experience_level TEXT DEFAULT 'Entry Level',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Resumes table
CREATE TABLE IF NOT EXISTS public.resumes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    full_name TEXT,
    email TEXT,
    phone TEXT,
    linkedin TEXT,
    github TEXT,
    education JSONB,
    skills JSONB,
    projects JSONB,
    experience JSONB,
    certifications JSONB,
    achievements JSONB,
    languages JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Skill Gaps table
CREATE TABLE IF NOT EXISTS public.skills (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    skills_list JSONB, -- String list of current skills
    gap_analysis JSONB, -- { missing_skills: [], courses: [], recommendations: [] }
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Career Roadmaps table
CREATE TABLE IF NOT EXISTS public.career_roadmaps (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    resume_id UUID REFERENCES public.resumes(id) ON DELETE CASCADE,
    target_role TEXT NOT NULL,
    roadmap_data JSONB,
    readiness_score INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Interview Sessions table
CREATE TABLE IF NOT EXISTS public.interview_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    resume_id UUID REFERENCES public.resumes(id) ON DELETE CASCADE,
    job_match_id UUID,
    interview_type TEXT,
    questions JSONB,
    answers JSONB,
    scores JSONB,
    feedback JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Job Matches table
CREATE TABLE IF NOT EXISTS public.job_matches (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    resume_id UUID REFERENCES public.resumes(id) ON DELETE CASCADE,
    job_title TEXT,
    company_name TEXT,
    job_description TEXT,
    match_score INTEGER,
    ats_score INTEGER,
    analysis_json JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Portfolios table
CREATE TABLE IF NOT EXISTS public.portfolios (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    resume_id UUID REFERENCES public.resumes(id) ON DELETE CASCADE,
    writing_style TEXT,
    portfolio_website JSONB,
    linkedin_optimization JSONB,
    github_optimization JSONB,
    networking_toolkit JSONB,
    branding_score JSONB,
    gap_analysis JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Recruiter Reviews table (combining Recruiter Review + Fraud Detection)
CREATE TABLE IF NOT EXISTS public.recruiter_reviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    resume_id UUID REFERENCES public.resumes(id) ON DELETE CASCADE,
    review_data JSONB, -- { score: 0, strengths: [], weaknesses: [], suggestions: [] }
    fraud_analysis JSONB, -- { rating: '', issues: [], warnings: [], score: 0 }
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Parsed Resumes table (specific fields, validation, and confidence checks)
CREATE TABLE IF NOT EXISTS public.parsed_resumes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    full_name TEXT,
    email TEXT,
    phone TEXT,
    linkedin TEXT,
    github TEXT,
    education JSONB, -- [ { school, degree, fieldOfStudy, startYear, endYear } ]
    skills JSONB, -- [ string ]
    projects JSONB, -- [ { name, description, technologies, githubUrl } ]
    experience JSONB, -- [ { company, position, location, startDate, endDate, description: [] } ]
    certifications JSONB, -- [ string ]
    achievements JSONB, -- [ string ]
    languages JSONB, -- [ string ]
    confidence_scores JSONB, -- { full_name: 0.9, email: 0.95, ... }
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Saved Opportunities table
CREATE TABLE IF NOT EXISTS public.saved_opportunities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    opportunity_data JSONB, -- { title, company, type, link, matches }
    status TEXT DEFAULT 'Saved',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enable Row Level Security on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resumes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.career_roadmaps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.interview_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.portfolios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recruiter_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parsed_resumes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_opportunities ENABLE ROW LEVEL SECURITY;

-- Profiles Policies to ensure users can only access their own data

-- Profiles Policies
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Resumes Policies
CREATE POLICY "Users can CRUD own resumes" ON public.resumes 
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Parsed Resumes Policies
CREATE POLICY "Users can CRUD own parsed resumes" ON public.parsed_resumes
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Saved Opportunities Policies
CREATE POLICY "Users can CRUD own saved opportunities" ON public.saved_opportunities 
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Analytics Events Table
CREATE TABLE IF NOT EXISTS public.analytics_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL,
    event_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own analytics" ON public.analytics_events 
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own analytics" ON public.analytics_events 
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Skills Policies
CREATE POLICY "Users can CRUD own skills" ON public.skills 
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Career Roadmaps Policies
CREATE POLICY "Users can CRUD own career roadmaps" ON public.career_roadmaps 
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Interview Sessions Policies
CREATE POLICY "Users can CRUD own interview sessions" ON public.interview_sessions 
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Job Matches Policies
CREATE POLICY "Users can CRUD own job matches" ON public.job_matches 
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Portfolios Policies
CREATE POLICY "Users can CRUD own portfolios" ON public.portfolios 
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Recruiter Reviews Policies
CREATE POLICY "Users can CRUD own recruiter reviews" ON public.recruiter_reviews 
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Automatically create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name)
    VALUES (new.id, new.email, COALESCE(new.raw_user_meta_data->>'full_name', ''));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to call trigger function on user insert
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();