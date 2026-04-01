// supabase/functions/approve-user/index.ts
// Supabase Edge Function: Approve or reject a pending user

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  try {
    const { user_id, action } = await req.json();

    // --- Validation -----------------------------------------------------------
    if (!user_id || typeof user_id !== "string") {
      return new Response(
        JSON.stringify({ error: "Missing or invalid 'user_id'" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const validActions = ["approve", "reject"];
    if (!action || !validActions.includes(action)) {
      return new Response(
        JSON.stringify({
          error: `Invalid action. Must be one of: ${validActions.join(", ")}`,
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // --- Supabase client (service role — bypasses RLS) -----------------------
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // --- Verify the user exists and is currently pending ---------------------
    const { data: profile, error: fetchError } = await supabase
      .from("profiles")
      .select("id, email, full_name, status")
      .eq("id", user_id)
      .single();

    if (fetchError || !profile) {
      return new Response(
        JSON.stringify({ error: "User not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (profile.status !== "pending") {
      return new Response(
        JSON.stringify({
          error: `User is already '${profile.status}'. Only pending users can be approved or rejected.`,
        }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // --- Update profile status -----------------------------------------------
    const newStatus = action === "approve" ? "active" : "suspended";

    const { error: updateError } = await supabase
      .from("profiles")
      .update({ status: newStatus })
      .eq("id", user_id);

    if (updateError) {
      console.error("Update error:", updateError);
      return new Response(
        JSON.stringify({ error: "Failed to update user status", details: updateError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // --- If approved, create a welcome notification for the user -------------
    if (action === "approve") {
      const { error: notifError } = await supabase
        .from("notifications")
        .insert({
          user_id,
          type: "approval_required",
          title: "Account Approved",
          body: "Your account has been approved. Welcome to Kuziini Task Manager!",
          data: { action: "account_approved" },
          is_read: false,
        });

      if (notifError) {
        // Log but don't fail the whole request over a notification
        console.error("Notification insert error:", notifError);
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        user_id,
        action,
        new_status: newStatus,
        message:
          action === "approve"
            ? `User ${profile.email} has been approved and is now active.`
            : `User ${profile.email} has been rejected and is now suspended.`,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("Unhandled error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
