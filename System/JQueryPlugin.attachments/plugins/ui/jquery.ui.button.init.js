"use strict";jQuery(function(a){var n={onlyVisible:!1};a(".jqUIButton").livequery(function(){var t=a(this),e=a.extend({},n,t.data(),t.metadata());t.removeClass("jqUIButton").button(e)}),a(".jqUIButtonset").livequery(function(){var t=a(this),e=a.extend({},n,t.data(),t.metadata());t.removeClass("jqUIButtonset").buttonset(e)})});
