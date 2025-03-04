{#- 
To run, alter this command

--simple example
dbt run-operation compare_objects --args "{comparison_schema : dbt_kevin, object_name: dw_claim_transaction_item_calendar_date_ungrouped, primary_key : 'claim_transaction_calendar_date_key'}"
dbt run-operation compare_objects --args "{comparison_schema : dbt_kevin, object_name: dw_claim_transaction_item_calendar_date_ungrouped, primary_key : 'claim_transaction_calendar_date_key', sql_where: calendar_date < '2020-08-15'}"

--example with updated prod_schema variable
dbt run-operation compare_objects --args "{comparison_schema : dbt_kevin_dw, prod_schema: dw, object_name: dw_claim_transaction_item_calendar_date_ungrouped, primary_key : 'claim_transaction_calendar_date_key'}"
dbt run-operation compare_objects --args "{comparison_schema : dbt_kevin_dw, prod_schema: dw, object_name: dw_claim_transaction_item_calendar_date_ungrouped, primary_key : 'claim_transaction_calendar_date_key', sql_where: calendar_date < '2020-08-15'}"

--example where you need to construct a primary key
dbt run-operation compare_objects --args "{comparison_schema : dbt_kevin, object_name: claim_transaction_calendar_date, primary_key : 'claim_uuid || claim_coverage_type ||  calendar_date'}"
dbt run-operation compare_objects --args "{comparison_schema: dbt_kevin, object_name: claim_transaction_calendar_date, primary_key : 'claim_uuid || claim_coverage_type ||  calendar_date', sql_where: calendar_date < '2020-05-01'}"

-#}
{% macro get_comparison_schema() %}
    {{ return(adapter.dispatch('get_comparison_schema', 'cc_dbt_utils')()) }}
{% endmacro %}

{% macro default__get_comparison_schema() %}

	{{ return(target.schema) }}

{% endmacro %}

{% macro create_comparison_schema() %}
    {{ return(adapter.dispatch('create_comparison_schema', 'cc_dbt_utils')()) }}
{% endmacro %}

{% macro default__create_comparison_schema() %}
	create schema if not exists {{ get_comparison_schema() }}
{% endmacro %}

{% macro get_comparison_results_relation() %}
    {{ return(adapter.dispatch('get_comparison_results_relation', 'cc_dbt_utils')()) }}
{% endmacro %}

{% macro default__get_comparison_results_relation() %}

	{%- set comp_schema=get_comparison_schema() -%}

	{%- set comp_table =
		api.Relation.create(
			database=target.database,
			schema=comp_schema,
			identifier='dbt_model_comparison_results',
			type='table'
		) -%}

	{{ return(comp_table) }}

{% endmacro %}

{% macro create_comparison_results_table() -%}
    {{ return(adapter.dispatch('create_comparison_results_table', 'cc_dbt_utils')()) }}
{% endmacro -%}

{% macro default__create_comparison_results_table() %}

	{% set required_columns = [
	   ["invocation_id", "varchar(512)"],
	   ["schema_name", "varchar(512)"],
	   ["relation_name", "varchar(512)"],
	   ["column_name", "varchar(512)"],
	   ["match_status", "varchar(512)"],
	   ["counts", "integer"],
       ["query", "varchar"],
	   ["created_at", cc_dbt_utils.type_timestamp()]
	] -%}

	{% set results_table = get_comparison_results_relation() %}

	{% set results_table_relation = adapter.get_relation(results_table.database, results_table.schema, results_table.name) %}

	{% do log('about to see if table exists', True) %}
	{% if results_table_relation -%}
	{% do log('it exists', True) %}
		{%- set columns_to_create = [] -%}

		{# map to lower to cater for snowflake returning column names as upper case #}
		{% do log('getting existing columns', True) %}
		{%- set existing_columns = adapter.get_columns_in_relation(results_table)|map(attribute='column')|map('lower')|list -%}
		{% do log('finished getting existing columns', True) %}
		
		{%- for required_column in required_columns -%}
			{%- if required_column[0] not in existing_columns -%}
				{%- do columns_to_create.append(required_column) -%}

			{%- endif -%}
		{%- endfor -%}

		{% do log('begin adding columns?', True) %}
		{%- for column in columns_to_create -%}
			{% set alter_table_sql %}
				alter table {{ results_table }}
				add column {{ column[0] }} {{ column[1] }}
				default null;
			{% endset %}
			{% do log('adding a column', True) %}
			{% do run_query(alter_table_sql) %}
		{% endfor -%}
		
		{% do log('no columns to add', True) %}
		
		{%- if columns_to_create|length > 0 %}
		{% do log('there was a column to change', True) %}
			commit;
		{% endif -%}

	{%- else -%}
		{% do log('it didnt exists, we will make it', True) %}
		{% set create_table_sql %}
			create table if not exists {{ results_table }}
			(
			{% for column in required_columns %}
				{{ column[0] }} {{ column[1] }}{% if not loop.last %},{% endif %}
			{% endfor %}
			)
		{% endset %}
		{% do run_query(create_table_sql) %}

	{%- endif -%}
	{% do log('table shit is done', True) %}
{%- endmacro %}

{% macro drop_comparison_results_relation() %}
    {{ return(adapter.dispatch('drop_comparison_results_relation', 'cc_dbt_utils')()) }}
{% endmacro %}

{% macro default__drop_comparison_results_relation() %}
		{% set drop_table_sql %}
			drop table if exists {{ get_comparison_results_relation() }}
		{% endset %}
		{% do run_query(drop_table_sql) %}
{% endmacro %}

{% macro log_comparison_results(invocation_id, schema_name, relation_name, column_name, match_status, counts, query) %}
    {{ return(adapter.dispatch('log_comparison_results', 'cc_dbt_utils')(invocation_id, schema_name, relation_name, column_name, match_status, counts, query)) }}
{% endmacro %}

{% macro default__log_comparison_results(invocation_id, schema_name, relation_name, column_name, match_status, counts, query) %}

	insert into {{ get_comparison_results_relation() }} (
		invocation_id,
		schema_name,
		relation_name,
		column_name,
		match_status,
		counts,
        query,
		created_at
	)

	values (
		{% if variable != None %}'{{ invocation_id }}'{% else %}null::varchar(512){% endif %},
		{% if variable != None %}'{{ schema_name }}'{% else %}null::varchar(512){% endif %},
		{% if variable != None %}'{{ relation_name }}'{% else %}null::varchar(512){% endif %},
		{% if variable != None %}'{{ column_name }}'{% else %}null::varchar(512){% endif %},
		{% if variable != None %}'{{ match_status }}'{% else %}null::varchar(512){% endif %},
		{% if variable != None %}'{{ counts }}'{% else %}null::int{% endif %},
        {% if variable != None %}{{ query }}{% else %}null::varchar{% endif %},
		{{ cc_dbt_utils.current_timestamp_in_utc() }}
	);
	
	commit;

{% endmacro %}

{% macro compare_objects( comparison_schema, object_name, primary_key, prod_database = 'ANALYTICS_DW', prod_schema = 'ANALYSIS', sql_where = none) %}
    {{ return(adapter.dispatch('compare_objects', 'cc_dbt_utils')(comparison_schema, object_name, primary_key, prod_database, prod_schema, sql_where)) }}
{% endmacro %}

{% macro default__compare_objects( comparison_schema
						  , object_name
						  , primary_key
						  , prod_database = 'ANALYTICS_DW'
						  , prod_schema = 'ANALYSIS'
						  , sql_where = none
						  ) %}

	{% do log('starting to check dev schema ', True) %}
	{% set check_schema = create_comparison_schema() %}
	{% do log('finished checking/creating dev schema ', True) %}
	
	{% do log('checking to see if the results table exists', True) %}
	{% set check_results_table = create_comparison_results_table() %}
	{% do log('results table is ready to go', True) %}
	
	{% set original_object = adapter.get_relation(prod_database, prod_schema, object_name) -%}
		{%- if original_object is none -%}
			{% do log('The original object {2}.{1}.{0} was not found, please double check your inputs or permissions if you believe your object definitely exists'.format(object_name, prod_schema, prod_database), True) %}
		{%- endif -%}

	{% set comparison_object = adapter.get_relation(target.database, comparison_schema, object_name) -%}
		{%- if comparison_object is none -%}
			{% do log('The comparison object {2}.{1}.{0} was not found, please double check your inputs or permissions if you believe your object definitely exists'.format(object_name, comparison_schema, target.database), True) %}
		{%- endif -%}

  	{%- set original_columns = adapter.get_columns_in_relation(original_object)|map(attribute='column')|map('lower')|list -%}
  	{%- set comparison_columns = adapter.get_columns_in_relation(comparison_object)|map(attribute='column')|map('lower')|list -%}
	{%- set original_only_columns = adapter.get_missing_columns(original_object, comparison_object)|map(attribute='column')|map('lower')|list -%}
	{%- set comparison_only_columns = adapter.get_missing_columns(comparison_object, original_object)|map(attribute='column')|map('lower')|list -%}
	{%- set total_columns = original_columns + comparison_only_columns -%}

  	{%- set invocation_id_value = run_query('select uuid_string()') -%}
  	{%- for column_name in total_columns -%}
		{% do log('starting column {0}.'.format(column_name), True) %}
		{% set compare_sql %}

		with original_object_cte as (

			select *,
			{%- for col in comparison_only_columns -%}
			null as {{ col }},
			{%- endfor -%}
			{{ primary_key }} as cv_primary_key from {{ original_object }} 
		),

		comparison_object_cte as (

			select *, 
			{%- for col in original_only_columns -%}
			null as {{ col }},
			{%- endfor -%}
			{{ primary_key }} as cv_primary_key from {{ comparison_object }} 
		)
			
			select 
					case
            			when equal_null(a.{{ column_name }}, b.{{ column_name }}) then 'perfect match'
            			when a.cv_primary_key is null then 'missing from original'
            			when b.cv_primary_key is null then 'missing from comparison'
            			when a.{{ column_name }} is null then 'value is null in original only'
            			when b.{{ column_name }} is null then 'value is null in comparison only'
            			when a.{{ column_name }} != b.{{ column_name }} then 'values do not match'
            			else 'unknown' -- this should never happen
        			end as match_status
				, count(coalesce(a.cv_primary_key, b.cv_primary_key)) as counts
			from original_object_cte as a
			full outer join comparison_object_cte as b
				on a.cv_primary_key = b.cv_primary_key
			where 1=1 {{ '\n  ' }}
			{%- if sql_where is not none -%}
			and a.{{ sql_where }} {{ '\n  ' }}
			{%- endif -%}
			group by 1
			
		{% endset %}
        
        
		{% set compare_sql_results = run_query(compare_sql) %}
        {% set compare_sql_string = '$$' ~ compare_sql|string ~ '$$' %}
		{%- for result in compare_sql_results.rows -%}

			{% set run_a = run_query(log_comparison_results(invocation_id = invocation_id_value.rows[0][0], schema_name=comparison_schema, relation_name = object_name, column_name = column_name, match_status = result[0], counts = result[1], query=compare_sql_string)) %}

		{%- endfor -%}

  	{%- endfor -%}

	{% do log('seems like we finished!', True) %}
    {% do log('check the dbt_model_comparison_results table in your comparison schema for the results, should be listed under invocation_id {0}:'.format(invocation_id_value.rows[0][0]), True) %}
    {% set query_string %}
        
    select *
    from {{target.database}}.{{target.schema}}.dbt_model_comparison_results
    where invocation_id = '{{ invocation_id_value.rows[0][0] }}'

    {% endset %}
    {% do log('{0}'.format(query_string), True) %}
    
{% endmacro %}


