# PAID-057 (A1): plans.json shape pre-flight for publish-package-action.
#
# Emits one publisher-facing error string per line for any shape violation; emits
# nothing when the shape is valid. This is a fast-fail CI pre-flight — the hub API
# (src/lib/PackagePlans.js) is the authoritative validator. Keep the two in sync.
#
# $product is the expected "PKG:<scope>/<name>" (empty string skips the match check).
#
# A package is paid iff it ships package/plans.json. This captures SHAPE only, never
# price — price is hub's half, set in the publisher UI.

def isobj: (type == "object");

( (keys - ["product","meters","plans"]) as $u
  | if ($u|length) > 0 then "plans.json has unknown key(s): " + ($u|join(", ")) else empty end ),

( if (.product|type) != "string" or ((.product // "")|gsub("\\s";"")|length) == 0
  then "plans.json 'product' must be a non-empty string"
  elif ($product != "" and .product != $product)
  then "plans.json 'product' is '\(.product)' but must be '\($product)' for this package"
  else empty end ),

( (.meters // {}) as $m
  | if ($m|isobj|not) then "plans.json 'meters' must be an object"
    else ( $m | to_entries[]
           | ( if (.key|test("^[a-z0-9][a-z0-9_-]*$")|not)
               then "plans.json meter name '\(.key)' must be lowercase and contain no spaces" else empty end ),
             ( if (.value|isobj) and (((.value|keys) - ["unit"])|length) > 0
               then "plans.json meter '\(.key)' has unknown key(s): " + (((.value|keys) - ["unit"])|join(", ")) else empty end ),
             ( if (.value|isobj) and (.value.unit != null) and ((.value.unit|type) != "string")
               then "plans.json meter '\(.key)' 'unit' must be a string" else empty end ) )
    end ),

( if (.plans|isobj|not) then "plans.json 'plans' must be an object"
  elif ((.plans|length) != 1) then "plans.json 'plans' must contain exactly one plan in v1 (found \(.plans|length))"
  else ( (.meters // {} | keys) as $declared
         | .plans | to_entries[]
         | .key as $tier | .value as $plan
         | ( if ($plan|isobj|not) then "plans.json plan '\($tier)' must be an object"
             else ( ( if (((($plan|keys) - ["type","interval","meters"]))|length) > 0
                      then "plans.json plan '\($tier)' has unknown key(s): " + ((($plan|keys) - ["type","interval","meters"])|join(", ")) else empty end ),
                    ( if ([$plan.type] | inside(["subscription","on-demand"]) | not)
                      then "plans.json plan '\($tier)' 'type' must be one of: subscription, on-demand" else empty end ),
                    ( if ($plan.type == "subscription") and ([$plan.interval] | inside(["monthly","once"]) | not)
                      then "plans.json plan '\($tier)' 'interval' must be one of: monthly, once" else empty end ),
                    ( if ($plan.type == "subscription") and ($plan.interval == "once") and ((($plan.meters // {})|length) > 0)
                      then "plans.json plan '\($tier)' combines interval 'once' with meters; a one-time purchase cannot meter usage" else empty end ),
                    ( if ($plan.type == "on-demand") and ($plan.interval != null)
                      then "plans.json plan '\($tier)' is 'on-demand' and must not declare an 'interval'" else empty end ),
                    ( ($plan.meters // {}) | to_entries[]
                      | .key as $pm | .value as $pmd
                      | ( if ($declared | index($pm)) == null
                          then "plans.json plan '\($tier)' references meter '\($pm)' which is not declared in top-level 'meters'" else empty end ),
                        ( if ($pmd|isobj) and (((($pmd|keys) - ["limit"]))|length) > 0
                          then "plans.json plan '\($tier)' meter '\($pm)' has unknown key(s): " + ((($pmd|keys) - ["limit"])|join(", ")) else empty end ),
                        ( if ($pmd|isobj) and ($pmd.limit != null) and (($pmd.limit|floor) != $pmd.limit)
                          then "plans.json plan '\($tier)' meter '\($pm)' 'limit' must be an integer" else empty end ) ) )
             end ) )
  end )
