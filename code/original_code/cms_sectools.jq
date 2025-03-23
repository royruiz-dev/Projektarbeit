## Disclaimer: this logic is built based on the process flow diagram found in the README.md
## If the process flow diagram changes, the logic below MUST be adapted accordingly
## * items are applicable for NETAPP switches
{
stdtls:     ["udagent","cmsid"],        # required for all hosts for DBG CMS compliance
audscn:     ["splunk","auditd","ccs"],  # ccs for Symantec CCS Agent, splunk & audit for Splunk (logs fw + Auditd)
vlnscn:     ["rapid7","hids"],          # hids for TrendMicro HIDS ds_agent, rapid7 for scanmgr as scan manager user that provides authorization for Rapid7
dbmon:      ["imperva"],                # imperva for db
syslog:     ["syslog"],                 # syslog* for NETAPP switches and storage - no agent, only protocol
scanmgr:    ["rapid7"],                 # rapid7 for scanmgr as scan manager user that provides authorization for Rapid7
solarwinds: ["solarwinds"],             # solarwinds* compliance covers related ccs and auditd implementation; applicable only for NETAPP switches
nidsnips:   ["nidsnips"]                # nidsnips* network security configuration; applicable only for NETAPP switches; not used because switches are not external facing
} as $sec
| if .CATEGORY == "SERVER" and (.ENV_PRODUCTION or .ENV_SIMULATION) and .APPLIANCE and .APPLIANCE_SEC_AGENT and (.INTERNET or .EXTERNAL)              then $sec | {audscn, vlnscn}
elif .CATEGORY == "SERVER" and (.ENV_PRODUCTION or .ENV_SIMULATION) and .APPLIANCE and .APPLIANCE_SEC_AGENT and (.INTERNET or .EXTERNAL | not)        then $sec | {audscn, scanmgr}
elif .CATEGORY == "SERVER" and (.ENV_PRODUCTION or .ENV_SIMULATION) and (.APPLIANCE | not) and (.INTERNET or .EXTERNAL) and .DB                       then $sec | {stdtls, audscn, vlnscn, dbmon}
elif .CATEGORY == "SERVER" and (.ENV_PRODUCTION or .ENV_SIMULATION) and (.APPLIANCE | not) and (.INTERNET or .EXTERNAL) and (.DB | not)               then $sec | {stdtls, audscn, vlnscn}
elif .CATEGORY == "SERVER" and (.ENV_PRODUCTION or .ENV_SIMULATION) and (.APPLIANCE | not) and (.INTERNET or .EXTERNAL | not) and .DB                 then $sec | {stdtls, audscn, scanmgr, dbmon}
elif .CATEGORY == "SERVER" and (.ENV_PRODUCTION or .ENV_SIMULATION) and (.APPLIANCE | not) and (.INTERNET or .EXTERNAL | not) and (.DB | not)         then $sec | {stdtls, audscn, scanmgr}
elif .CATEGORY == "SERVER" and (.ENV_ACCEPTANCE or .ENV_DEVELOPMENT or .ENV_TEST) and (.APPLIANCE | not) and (.INTERNET or .EXTERNAL) and .DB         then $sec | {stdtls, vlnscn, dbmon}
elif .CATEGORY == "SERVER" and (.ENV_ACCEPTANCE or .ENV_DEVELOPMENT or .ENV_TEST) and (.APPLIANCE | not) and (.INTERNET or .EXTERNAL) and (.DB | not) then $sec | {stdtls, vlnscn}
elif .CATEGORY == "SWITCH" and .ENV_PRODUCTION and (.INTERNET or .EXTERNAL)                                                                           then $sec | {syslog, solarwinds, nidsnips}
elif .CATEGORY == "SWITCH" and .ENV_PRODUCTION and ((.INTERNET or .EXTERNAL) | not)                                                                   then $sec | {syslog, solarwinds}
elif .CATEGORY == "STORAGE" and (.ENV_PRODUCTION or .ENV_SIMULATION)                                                                                  then $sec | {syslog}
elif .APPLIANCE | not                                                                                                                                 then $sec | {stdtls}
else null end
| if . then add | unique else . end