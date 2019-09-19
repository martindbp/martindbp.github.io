{% extends 'basic.tpl' %}

{% block header scoped %}
    <style>
      .toggleon .showbutton {
        display: none;
      }
      .toggleoff .hidebutton {
        display: none;
      }
      .toggleoff .cellwrapper {
        display: none
      }
    </style>
    <script type="text/javascript">
      var toggle = function(id) {
        toggleDiv = id.parentNode.parentNode
        if (toggleDiv.classList.contains('toggleon')) {
          toggleDiv.classList.remove('toggleon');
          toggleDiv.classList.add('toggleoff');
        }
        else {
          toggleDiv.classList.remove('toggleoff');
          toggleDiv.classList.add('toggleon');
        }
      };
    </script>
{%- endblock header %}

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
          <div class="{{'toggleon' if 'input_on' in tags else 'toggleoff'}}">
              <div style="display: flex; justify-content: flex-start">
                <a class='showbutton' onclick="toggle(this)" style="cursor: pointer">show code</a>
                <a class='hidebutton' onclick="toggle(this)" style="cursor: pointer">hide code</a>
              </div>
            <div class="cellwrapper">
              {{ super() }}
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
