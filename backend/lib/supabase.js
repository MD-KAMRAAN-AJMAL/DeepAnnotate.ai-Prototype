import { createClient } from '@supabase/supabase-js'

const { SUPABASE_URL: supabaseUrl, SUPABASE_KEY: supabaseKey } = process.env;

export const supabase = createClient(supabaseUrl, supabaseKey);
