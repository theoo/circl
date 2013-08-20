// Theses two methods are generic for date and datetime values 
// (which are basically big int)
var sort_date_asc_function = function ( a, b ) {
  return ((a < b) ? -1 : ((a > b) ? 1 : 0));
};

var sort_date_desc_function = function ( a, b ) {
  return ((a < b) ? 1 : ((a > b) ? -1 : 0));
};

// This method add sorting function to "circl-date(time)"
// tagged cells.
jQuery.extend( jQuery.fn.dataTableExt.oSort, {
  "circl-datetime-pre": function ( sData ) {
    if ($.trim(sData) != '') {
      var datetime = $.trim(sData).split(' ');
      var time    = datetime[1].split(':');
      var hour    = time[0]
      var minute  = time[1]

      var date    = datetime[0].split('-');
      var day     = date[0];
      var month   = date[1];
      var year    = date[2];

      return (year + month + day + hour + minute) * 1;
    } else {
      return 10000000000000; // year 1000
    }
  },

  "circl-datetime-asc": sort_date_asc_function,
  "circl-datetime-desc": sort_date_desc_function,

  "circl-date-pre": function ( sData ) {
    if ($.trim(sData) != '') {
      date_string = $.trim(sData);
      var date    = date_string.split("-");
      var day     = date[0];
      var month   = date[1];
      var year    = date[2];

      return (year + month + day) * 1;
    } else {
      return 10000000; // year 1000
    }
  },
  "circl-date-asc": sort_date_asc_function,
  "circl-date-desc": sort_date_desc_function,

} );

// this method scan cell data and tag it as "circl-datetime" if
// it matches the regexp
jQuery.fn.dataTableExt.aTypes.unshift(
  function (sData) {
    sData = $.trim(sData);
    if (sData.match(/^[0-9]+\-[0-9]+\-[0-9]+\s[0-9]+\:[0-9]+$/)) {
      return 'circl-datetime';
    }
    if (sData.match(/^[0-9]+\-[0-9]+\-[0-9]+$/)) {
      return 'circl-date';
    }
    return null;
  }
);