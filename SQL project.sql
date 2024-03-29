-- Creating a temporary table containing the age of customers
CREATE TEMPORARY TABLE banca.den_age AS
SELECT 
    cust.id_cliente,
    TIMESTAMPDIFF(YEAR, cust.data_nascita, CURRENT_DATE()) AS age
FROM 
    banca.cliente cust;

-- Creation of a temporary table containing the total number of accounts and the number of accounts per type
CREATE TEMPORARY TABLE banca.den_accounts AS
SELECT 
    cust.id_cliente,
    COUNT(DISTINCT acc.id_conto) AS number_accounts,
    COUNT(DISTINCT CASE WHEN tacc.desc_tipo_conto = 'Conto Base' THEN acc.id_conto END) AS number_accounts_basic,
    COUNT(DISTINCT CASE WHEN tacc.desc_tipo_conto = 'Conto Business' THEN acc.id_conto END) AS number_accounts_business,
    COUNT(DISTINCT CASE WHEN tacc.desc_tipo_conto = 'Conto Privati' THEN acc.id_conto END) AS number_accounts_private,
    COUNT(DISTINCT CASE WHEN tacc.desc_tipo_conto = 'Conto Famiglie' THEN acc.id_conto END) AS number_accounts_family
FROM 
    banca.cliente cust
LEFT JOIN 
    banca.conto acc ON cust.id_cliente = acc.id_cliente
LEFT JOIN 
    banca.tipo_conto tacc ON acc.id_tipo_conto = tacc.id_tipo_conto
GROUP BY 
    cust.id_cliente;

-- Creation of a temporary table containing transaction information
CREATE TEMPORARY TABLE banca.den_transactions AS
SELECT 
    cust.id_cliente,
    SUM(CASE WHEN ttra.segno = '-' THEN 1 ELSE 0 END) AS number_transactions_outgoing_accounts,
    SUM(CASE WHEN ttra.segno = '+' THEN 1 ELSE 0 END) AS number_transactions_incoming_accounts,
    ROUND(SUM(CASE WHEN ttra.segno = '-' THEN tra.importo ELSE 0 END), 2) AS expenditure_total_amount,
    ROUND(SUM(CASE WHEN ttra.segno = '+' THEN tra.importo ELSE 0 END), 2) AS income_total_amount,
    SUM(CASE WHEN ttra.desc_tipo_trans = 'Acquisto su Amazon' THEN 1 ELSE 0 END) AS num_transactions_outgoing_amazon,
	SUM(CASE WHEN ttra.desc_tipo_trans = 'Rata mutuo' THEN 1 ELSE 0 END) AS num_transactions_outgoing_mortgage,
	SUM(CASE WHEN ttra.desc_tipo_trans = 'Hotel' THEN 1 ELSE 0 END) AS num_transactions_outgoing_hotel,
	SUM(CASE WHEN ttra.desc_tipo_trans = 'Biglietto aereo' THEN 1 ELSE 0 END) AS num_transactions_outgoing_plane,
	SUM(CASE WHEN ttra.desc_tipo_trans = 'Supermercato' THEN 1 ELSE 0 END) AS num_transactions_outgoing_supermarket,
	SUM(CASE WHEN ttra.desc_tipo_trans = 'Stipendio' THEN 1 ELSE 0 END) AS num_transactions_incoming_salary,
	SUM(CASE WHEN ttra.desc_tipo_trans = 'Pensione' THEN 1 ELSE 0 END) AS num_transactions_incoming_retirement,
	SUM(CASE WHEN ttra.desc_tipo_trans = 'Dividendi' THEN 1 ELSE 0 END) AS num_transactions_incoming_dividends,
    SUM(CASE WHEN ttra.segno = '-' AND tacc.desc_tipo_conto = 'Conto Base' THEN tra.importo ELSE 0 END) AS expenditure_basic_account,
    SUM(CASE WHEN ttra.segno = '+' AND tacc.desc_tipo_conto = 'Conto Base' THEN tra.importo ELSE 0 END) AS income_basic_account,
    SUM(CASE WHEN ttra.segno = '-' AND tacc.desc_tipo_conto = 'Conto Business' THEN tra.importo ELSE 0 END) AS expenditure_business_account,
    SUM(CASE WHEN ttra.segno = '+' AND tacc.desc_tipo_conto = 'Conto Business' THEN tra.importo ELSE 0 END) AS income_business_account,
    SUM(CASE WHEN ttra.segno = '-' AND tacc.desc_tipo_conto = 'Conto Privati' THEN tra.importo ELSE 0 END) AS expenditure_private_account,
    SUM(CASE WHEN ttra.segno = '+' AND tacc.desc_tipo_conto = 'Conto Privati' THEN tra.importo ELSE 0 END) AS income_private_account,
    SUM(CASE WHEN ttra.segno = '-' AND tacc.desc_tipo_conto = 'Conto Famiglie' THEN tra.importo ELSE 0 END) AS expenditure_family_account,
    SUM(CASE WHEN ttra.segno = '+' AND tacc.desc_tipo_conto = 'Conto Famiglie' THEN tra.importo ELSE 0 END) AS income_family_account
FROM 
    banca.cliente cust
LEFT JOIN 
    banca.conto acc ON cust.id_cliente = acc.id_cliente
LEFT JOIN 
    banca.transazioni tra ON acc.id_conto = tra.id_conto
LEFT JOIN 
    banca.tipo_transazione ttra ON tra.id_tipo_trans = ttra.id_tipo_transazione
LEFT JOIN 
    banca.tipo_conto tacc ON acc.id_tipo_conto = tacc.id_tipo_conto
GROUP BY 
    cust.id_cliente;

-- Merging temporary tables into a denormalised table
CREATE TABLE banca.denormalized AS
SELECT 
    age.id_cliente AS customer_id,
    age.age AS age,
    trans.number_transactions_outgoing_accounts AS number_transactions_outgoing_accounts,
    trans.number_transactions_incoming_accounts AS number_transactions_incoming_accounts,
    trans.expenditure_total_amount AS expenditure_total_amount,
    trans.income_total_amount AS income_total_amount,
    acc.number_accounts AS number_accounts,
    acc.number_accounts_basic AS number_accounts_basic,
    acc.number_accounts_business AS number_accounts_business,
    acc.number_accounts_private AS number_accounts_private,
    acc.number_accounts_family AS number_accounts_family,
    trans.num_transactions_outgoing_amazon AS num_transactions_outgoing_amazon,
    trans.num_transactions_outgoing_mortgage AS num_transactions_outgoing_mortgage,
    trans.num_transactions_outgoing_hotel AS num_transactions_outgoing_hotel,
    trans.num_transactions_outgoing_plane AS num_transactions_outgoing_plane,
    trans.num_transactions_outgoing_supermarket AS num_transactions_outgoing_supermarket,
    trans.num_transactions_incoming_salary AS num_transactions_incoming_salary,
    trans.num_transactions_incoming_retirement AS num_transactions_incoming_retirement,
    trans.num_transactions_incoming_dividends AS num_transactions_incoming_dividends,
    trans.expenditure_basic_account AS expenditure_basic_account,
    trans.income_basic_account AS income_basic_account,
    trans.expenditure_business_account AS expenditure_business_account,
    trans.income_business_account AS income_business_account,
    trans.expenditure_private_account AS expenditure_private_account,
    trans.income_private_account AS income_private_account,
    trans.expenditure_family_account AS expenditure_family_account,
    trans.income_family_account AS income_family_account
FROM 
    banca.den_age age
LEFT JOIN 
    banca.den_accounts acc ON age.id_cliente = acc.id_cliente
LEFT JOIN 
    banca.den_transactions trans ON age.id_cliente = trans.id_cliente;

-- Removal of temporary table identification columns from the denormalised table
ALTER TABLE banca.denormalized 
DROP COLUMN customer_id;

-- Delete previously created temporary tables
DROP TABLE IF EXISTS banca.den_age, banca.den_accounts, banca.den_transactions;

-- Exporting the denormalised table to a CSV file
/*
Since I want to create a CSV file with the field names in the first row, and 
manually writing all of them is tedious, I use the result of the following query:
*/

SELECT GROUP_CONCAT(CONCAT("'",COLUMN_NAME,"'") 
					ORDER BY ordinal_position) AS column_names
FROM information_schema.COLUMNS
WHERE TABLE_NAME = 'denormalized'
AND table_schema = 'banca';

/*
We perform a 'Copy Row (unquoted)' of the result and paste it in the final
query to export the view to a CSV file called "denormalized_table.csv":
*/

/*
After obtaining the column names, we perform the following operation:
    1. We select the data from the denormalised table
    2. Merge the results with the column names obtained previously
    3. We export the result to a CSV file called "denormalised_table.csv".
*/

SELECT 
    'age','number_transactions_outgoing_accounts','number_transactions_incoming_accounts','expenditure_total_amount',
    'income_total_amount','number_accounts','number_accounts_basic','number_accounts_business','number_accounts_private',
    'number_accounts_family','num_transactions_outgoing_amazon','num_transactions_outgoing_mortgage','num_transactions_outgoing_hotel',
    'num_transactions_outgoing_plane','num_transactions_outgoing_supermarket','num_transactions_incoming_salary',
    'num_transactions_incoming_retirement','num_transactions_incoming_dividends','expenditure_basic_account','income_basic_account',
    'expenditure_business_account','income_business_account','expenditure_private_account','income_private_account',
    'expenditure_family_account','income_family_account'


UNION ALL

SELECT 
	age,number_transactions_outgoing_accounts,number_transactions_incoming_accounts,expenditure_total_amount,
    income_total_amount,number_accounts,number_accounts_basic,number_accounts_business,number_accounts_private,
    number_accounts_family,num_transactions_outgoing_amazon,num_transactions_outgoing_mortgage,num_transactions_outgoing_hotel,
    num_transactions_outgoing_plane,num_transactions_outgoing_supermarket,num_transactions_incoming_salary,
    num_transactions_incoming_retirement,num_transactions_incoming_dividends,expenditure_basic_account,income_basic_account,
    expenditure_business_account,income_business_account,expenditure_private_account,income_private_account,
    expenditure_family_account,income_family_account
FROM 
    banca.denormalized
INTO OUTFILE 'C:\\Users\\crist\\Desktop\\Profession AI\\9 - SQL\\denormalized_table.csv'
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n';