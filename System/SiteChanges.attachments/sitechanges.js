!function(e){function n(e){s&&console&&console.log("setOptionSelected:inId="+e);var n=document.getElementById(e);n&&(n.selected="selected")}function t(){if(foswiki.Pref.getPref("WebChangesForAllWebs_dateLastCheck")){var t=e('input[name="sinceReadable"]').val();s&&console&&console.log("sinceReadable selectedOption:"+t),n(t||"24_hours_ago")}var o=new Date,c=o.getFullYear()+"-"+(o.getMonth()+1)+"-"+o.getDate()+" "+o.getHours()+":"+o.getMinutes()+":"+o.getSeconds();c=c.replace(/([-: ])(\d)([-: ]|$)/g,"$10$2$3"),s&&console&&console.log("now:"+c),c&&(foswiki.Pref.setPref(foswiki.getPreference("WEB")+"_"+foswiki.getPreference("TOPIC")+"_dateLastCheck",c),function(e){var n=document.getElementById("last_time_checked");n&&(n.value=e,n.text="last time I checked")}(c))}function o(){document.forms.seeChangesSince.web.value=document.forms.seeChangesSince.web.value.replace(/\s*,\s*/,", "),function(e){s&&console&&console.log("submitted:"+e)}(document.forms.seeChangesSince.since.value),document.forms.seeChangesSince.submit()}var s;e(function(){s=e("input[name='debugJs']").val(),e("#siteChangesSelect").change(function(){var n=e("option:selected",this);!function(e,n,t){s&&console&&console.log("storeSelectedOption:inName="+e+";inValue="+n+";inStorageField="+t),t.value=e}(n.attr("id"),n.attr("value"),document.forms.seeChangesSince.sinceReadable),o()}),e(document.forms.seeChangesSince).submit(function(){o()}),t()})}(jQuery);