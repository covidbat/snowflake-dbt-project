{# Standard NPS bucketing: 9-10 promoter, 7-8 passive, 0-6 detractor. #}
{% macro nps_category(score_col) -%}
    case
        when {{ score_col }} >= 9 then 'Promoter'
        when {{ score_col }} >= 7 then 'Passive'
        when {{ score_col }} >= 0 then 'Detractor'
        else 'Invalid'
    end
{%- endmacro %}
