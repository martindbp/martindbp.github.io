function code_toggle() {
    if (!code_show){
      $('div.input').hide();
    //$('div.prompt.output_prompt').hide();  //unnecessary since I'm hiding all prompts anyways in css
    } else {
      $('div.input').show();
    }
   code_show = !code_show
}
