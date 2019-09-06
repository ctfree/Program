        Direct transmission
        WUB 14 dbm
        Data 9dbm
        
        
        Relay transmission
        WUB 12 dbm
        Data 6 dbm
        
        
 pa_cfg2.pa_power_ramp = round( 2.3173*tx_pwr_dbm + 28.909 )

where tx_pwr_dbm is your desired TX Power (-11..14)

pa_cfg0.ask_depth = floor( pa_cfg2.pa_power_ramp/4 )

output power -5.5 dbm calculated by the theorical formula
output power -8 dbm found experimentaly

this value is used to send wake up beacon with the relay

