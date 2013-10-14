$(document).ready ->
  # index

  directory = new Directory

  # filters.bind 'search_query', Directory.search

  # This will load 'new person' widget, if button is present.
  # User may not have access to this widget
  # $('#add_new_person').on 'click', (e) ->
  #   container_id = 'add-new-person'
  #   widget = Ui.stack_window(container_id, {width: 500, position: ['top', 30], remove_on_close: true})
  #   people_controller = new App.People({el: widget})
  #   people_controller.activate()
  #   widget.modal({title: I18n.t('directory.views.add_person')})
  #   widget.modal('show')
  #   Ui.bind_datepicker()

  # finally load ui
  # FIXME: loading Ui.load_ui($(document)) doesn't
  # load the contextual menu on datatable
  # Ui.load_ui($("#content"))
  # Ui.load_ui($("header"))
