-- IMPORT DRINKS
insert into drinks (id, name, abv, instructions, glass_id) select * from dblink('dbname=tipsy_source', 'select drink_id, name, case when alcohol_contents is null or char_length(alcohol_contents) = 0 then null else cast(regexp_replace(alcohol_contents,''\D'',''0'') as integer) end, instructions, glass_id from drinks') as t(a integer, b varchar(255), c integer, d text, e integer);
-- IMPORT INGREDIENTS
insert into ingredients (id, name) select * from dblink('dbname=tipsy_source', 'select ingredient_id, name from ingredients') as t(a integer, b varchar(255));
-- IMPORT DRINK INGREDIENTS
insert into drinks_ingredients (drink_id, ingredient_id, qty) select * from dblink('dbname=tipsy_source', 'select drink_id, ingredient_id, amount from servings') as t(a integer, b integer, c varchar(255));
