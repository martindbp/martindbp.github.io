{% extends 'basic.tpl' %}

{% block codecell scoped %}
  {% set tags = cell['metadata'].get('tags', []) %}
  {% if 'remove' not in tags %}
    {% if 'remove_input' not in tags %}
      {% block input_group scoped %}
        {% block in_prompt scoped %}
        {% endblock in_prompt %}

        {% if not 'toggle_input' in tags %}
          {{ super() }}
        {% else %}
          {% set cell_text = super() %}
          {% set code_lines = cell_text.split('\n') | length %}
          <div class="{{'toggleon' if 'input_on' in tags else 'toggleoff'}}">
              <div style="display: flex; justify-content: flex-start">
                <a class='showbutton' onclick="toggle(this)" style="cursor: pointer">show code ({{ code_lines }} line{{'s' if code_lines > 1 else ''}})</a>
                <a class='hidebutton' onclick="toggle(this)" style="cursor: pointer">hide code</a>
              </div>
            <div class="cellwrapper">
              {{ cell_text }}
            </div>
          </div>
        {% endif %}
      {%- endblock input_group %}
    {% endif %}

    {% if 'remove_output' not in tags %}
      {% block output_group scoped %}
        {% block output_prompt scoped %}
        {% endblock output_prompt %}
        {% if not 'toggle_output' in tags %}
          {{ super() }}
        {% else %}
          <div class="{{'toggleoff' if 'output_off' in tags else 'toggleon'}}">
              <div style="display: flex; justify-content: flex-start">
                <a class='showbutton' onclick="toggle(this)" style="cursor: pointer">show output</a>
                <a class='hidebutton' onclick="toggle(this)" style="cursor: pointer">hide output</a>
              </div>
            <div class="cellwrapper">
              {{ super() }}
            </div>
          </div>
        {% endif %}
      {%- endblock output_group %}
    {% else %}
      </br>
    {% endif %}
  {% endif %}
{%- endblock codecell %}
{% block markdowncell scoped %}
  {% set tags = cell['metadata'].get('tags', []) %}
  {% if 'remove' not in tags %}
    {{ super() }}
  {% endif %}
{%- endblock markdowncell %}
