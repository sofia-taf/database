call sofia_taf.import_current_status('31', '2022Area31CatchEffortGlobalv2JM', '', 2, 546, '', 'current');
call sofia_taf.import_current_status('31', '2022Area31effortlocalcatchlocalv2JM', '', 2, 546, '', 'current');
call sofia_taf.import_current_status('31', '2022Area31IndexMethodv2JM', '', 2, 546, '', 'current');
update current_status set stock = 'Holothuroidea' WHERE stock ='Holothuriidae';