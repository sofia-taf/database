INSERT INTO `sofia_taf`.`reference`
(`citation`,
`publication_DOI`,
`contact`,
`data_DOI_URL`,
`status`)
SELECT
'FAO 2023. ASFIS List of Species for Fishery Statistics Purposes. Fisheries and Aquaculture Division [online]. Rome. [Cited Sunday, January 22nd 2023].https://www.fao.org/fishery/en/collection/asfis/en '
,publication_DOI
,contact
,'https://www.fao.org/fishery/en/collection/asfis/en'
, status 
FROM sofia_taf.reference where id = 446;

update reference set status = 'superseded' where  id = 446;

