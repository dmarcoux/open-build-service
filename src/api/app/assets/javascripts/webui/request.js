function updateSupersedeAndDevelPackageDisplay() {
  if ($('#targetproject').length > 0 && $('#targetproject')[0].value.length > 2) {
    if ($('#targetproject')[0].value === $('#sourceproject')[0].value) {
      $('#sourceupdate-display').hide();
      $('#sourceupdate').prop('disabled', true); // hide 'sourceupdate' from Ruby
    } else {
      $('#sourceupdate-display').show();
      $('#sourceupdate').prop('disabled', false);
    }
    $.ajax({
      url: $('#targetproject').data('requests-url'),
      data: {
        project: $('#targetproject')[0].value,
        source_project: $('#project')[0].value, // jshint ignore:line
        package: $('#package')[0].value,
        types: 'submit',
        states: ['new', 'review', 'declined']
      },
      success: function (data) {
        if (data.indexOf('No requests') === -1) {
          $('#supersede-display').removeClass('d-none');
          $('#supersede-requests').html(data);
        } else {
          $('#supersede-display').addClass('d-none');
          $('#supersede-requests').html('');
        }
      }
    });
    $.ajax({
      url: $('#targetproject').data('develpackage-url'),
      data: {
        project: $('#targetproject')[0].value,
        package: $('#package')[0].value
      },
      success: function (data) {
        if (data.length > 0) {
          $('#devel-project-warning').removeClass('d-none');
          $('#devel-project-name').html(data);
        } else {
          $('#devel-project-warning').addClass('d-none');
        }
      }
    });
  }
}

function setupRequestDialog(url) { // jshint ignore:line
  $('#devel-project-name').click(function () {
    $('#targetproject').attr('value', $('#devel-project-name').html());
  });

  $('#targetproject.obs-autocomplete').on('autocompleteselect autocompletechange', function() {
    updateSupersedeAndDevelPackageDisplay();
  });

  prefillSubmitRequestForm(url);
}

/*
  This prefills the dialog with data coming from the package prefill endpoint.
*/
function prefillSubmitRequestForm(url) {
  $.ajax({
    url: url,
    dataType: 'json',
    contentType: 'application/json; charset=utf-8',
    accept: 'application/json',
    success: function (e) {
      $('#targetpackage').attr('value', e.targetPackage);
      $('#targetproject').attr('value', e.targetProject);
      $('#description').val(e.description);
      $('#sourceupdate').attr('checked', e.cleanupSource);
      updateSupersedeAndDevelPackageDisplay();
    }
  });
}

function toggleAutocomplete(autocompleteElement) { // jshint ignore:line
  $('.hideable').addClass('d-none');
  $('.hideable input:not(:visible)').attr('disabled', true);

  var selected = $(autocompleteElement+':checked').attr('value');
  $('.' + selected).removeClass('d-none');
  $('.hideable input:visible').removeAttr('disabled');
}

// TODO: Rename once modals depending on the non-responsive-ux version are all removed
function requestAddAutocompleteResponsiveUx(autocompleteElement) { // jshint ignore:line
  toggleAutocomplete(autocompleteElement);

  $(autocompleteElement).change(function () { toggleAutocomplete(autocompleteElement); });
}

// TODO: Remove once modals depending on this are all removed
function requestAddAutocomplete(autocompleteElement) { // jshint ignore:line
  $('.modal').on('shown.bs.modal', function() {
    $('.hideable input:not(:visible)').attr('disabled', true);
  });

  $(autocompleteElement).change(function () {
    $('.hideable').addClass('d-none');
    $('.hideable input:not(:visible)').attr('disabled', true);

    var selected = $(autocompleteElement+' option:selected').attr('value');
    $('.' + selected).removeClass('d-none');
    $('.hideable input:visible').removeAttr('disabled');
  });
}
