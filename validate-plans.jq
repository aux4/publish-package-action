# Fast-fail mirror of Hub's authoritative plans.json validator.

def isobj: (type == "object");
def validkey: test("^[a-z0-9][a-z0-9_-]{0,63}$");

(if (type != "object") then "plans.json must be a JSON object" else empty end),

(if type == "object" then
  ((keys - ["schemaVersion","metrics","plans"]) as $u
    | if ($u|length) > 0 then "plans.json has unknown key(s): " + ($u|join(", ")) else empty end),
  (if .schemaVersion != 1 then "plans.json 'schemaVersion' must be 1" else empty end),
  (if (.metrics|isobj|not) then "plans.json 'metrics' must be an object"
   else (.metrics | to_entries[]
     | if (.key|validkey|not) then "plans.json metric key '\(.key)' is invalid" else empty end,
       if (.value|isobj|not) then "plans.json metric '\(.key)' must be an object"
       else (((.value|keys) - ["label"]) as $u
         | if ($u|length) > 0 then "plans.json metric '\(.key)' has unknown key(s): " + ($u|join(", ")) else empty end),
         if ((.value.label|type) != "string") or ((.value.label|gsub("^\\s+|\\s+$";"")|length) == 0) or ((.value.label|length) > 80)
         then "plans.json metric '\(.key)' 'label' must be a non-empty string of at most 80 characters" else empty end
       end)
   end),
  (if (.plans|isobj|not) then "plans.json 'plans' must be an object"
   elif ((.plans|length) != 1) then "plans.json 'plans' must contain exactly one plan in v1 (found \(.plans|length))"
   else ((.metrics // {} | keys) as $declared
     | .plans | to_entries[]
     | .key as $planKey | .value as $plan
     | if ($planKey|validkey|not) then "plans.json plan key '\($planKey)' is invalid"
       elif ($plan|isobj|not) then "plans.json plan '\($planKey)' must be an object"
       else (((($plan|keys) - ["limits","price"])) as $u
         | if ($u|length) > 0 then "plans.json plan '\($planKey)' has unknown key(s): " + ($u|join(", ")) else empty end),
         if ($plan.price|isobj|not) then "plans.json plan '\($planKey)' 'price' must be an object"
         else (((($plan.price|keys) - ["monthly"])) as $u
           | if ($u|length) > 0 then "plans.json plan '\($planKey)' 'price' has unknown key(s): " + ($u|join(", ")) else empty end),
           if (($plan.price.monthly|type) != "number") or ($plan.price.monthly <= 0)
           then "plans.json plan '\($planKey)' 'price.monthly' must be a positive number"
           else empty end
         end,
         if ($plan.limits|isobj|not) then "plans.json plan '\($planKey)' 'limits' must be an object"
         else ($plan.limits | to_entries[]
           | .key as $metricKey | .value as $limit
           | if ($declared|index($metricKey)) == null then "plans.json plan '\($planKey)' references undeclared metric '\($metricKey)'"
             elif (($limit|type) != "number") or (($limit|floor) != $limit) or ($limit < -1)
             then "plans.json plan '\($planKey)' limit for '\($metricKey)' must be -1, 0, or a positive integer"
             else empty end),
           ($declared - ($plan.limits|keys))[] as $missing
             | "plans.json plan '\($planKey)' is missing limit for '\($missing)'"
         end
       end)
   end)
else empty end)
