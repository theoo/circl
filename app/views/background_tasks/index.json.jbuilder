
json.array! @tasks do |task|

  json.uuid       task.uuid
  json.title      I18n.t(*task["translation_options"])
  json.status     task.status
  json.created_at I18n.l(task.time)
  json.num        task.num
  json.total      task.total
  json.percentage task.pct_complete
  json.working    task.working?
  json.message    task.message

end