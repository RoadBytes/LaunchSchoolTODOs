$(function() {
  $("form.delete").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();

    var ok = confirm("Are you sure? This cannot be undone!");

    if(ok) {
      var form = $(this);

      var request = $.ajax({
        url: form.attr("action"),
        method: form.attr("method")
      });

      request.done(function(data, textStatus, jqXHR) {
        if (jqXHR.status == 204) {
          form.parent('li').remove();
          $("div.flash.success").text("Todo Xml Deleted");
        } else if (jqXHR.status == 200) {
          document.location = data;
          $("div.flash.success").text("List Xml Deleted");
        }
      });
    }
  });
});
