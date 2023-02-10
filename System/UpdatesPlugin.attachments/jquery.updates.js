"use strict";!function(o){function i(i){var e=this;return e.options=o.extend({},t,i),e.options.debug&&console.log("called new FoswikiUpdates"),e.init(),e.loadPluginInfo(0),e}var e,t={configureUrl:void 0,endpointUrl:void 0,debug:!1,delay:1e3,timeout:5e3,cookieName:"FOSWIKI_UPDATESPLUGIN",cookieExpires:7,cookieSecure:"0",cookieDomain:""};i.prototype.init=function(){var i=this;void 0===i.options.configureUrl&&(i.options.configureUrl=foswiki.getPreference("UPDATESPLUGIN::CONFIGUREURL")),void 0===i.options.endpointUrl&&(i.options.endpointUrl=foswiki.getScriptUrl("rest","UpdatesPlugin","check")),i.options.cookieSecure=0===foswiki.getPreference("URLHOST").indexOf("https://"),o(document).on("refresh.foswikiUpdates",function(){i.loadPluginInfo(0)}),o(document).on("forceRefresh.foswikiUpdates",function(){o.cookie(i.options.cookieName,null,{expires:-1,path:"/",domain:i.options.cookieDomain,secure:i.options.cookieSecure}),i.loadPluginInfo(1)}),o(document).on("display.foswikiUpdates",function(){i.displayPluginInfo()}),o(document).on("click","#foswikiUpdatesIgnore",function(){return o.cookie(i.options.cookieName,[],{expires:i.options.cookieExpires,path:"/",domain:i.options.cookieDomain,secure:i.options.cookieSecure}),o(".foswikiUpdatesMessage").fadeOut(),!1})},i.prototype.loadPluginInfo=function(i){var e=this;e.outdatedPlugins=o.cookie(e.options.cookieName),void 0===e.outdatedPlugins?window.setTimeout(function(){o.ajax({type:"get",url:e.options.endpointUrl,dataType:"json",timeout:e.options.timeout,success:function(t){e.outdatedPlugins=t,o.cookie(e.options.cookieName,e.outdatedPlugins,{expires:e.options.cookieExpires,path:"/",domain:e.options.cookieDomain,secure:e.options.cookieSecure}),(e.outdatedPlugins.length>0||i)&&o(document).trigger("display.foswikiUpdates")},error:function(){o.cookie(e.options.cookieName,-1,{expires:e.options.cookieExpires,path:"/",domain:e.options.cookieDomain,secure:e.options.cookieSecure})}})},e.options.delay):("string"==typeof e.outdatedPlugins&&e.outdatedPlugins.length>0&&(e.outdatedPlugins=e.outdatedPlugins.split(/\s*,\s*/)),e.outdatedPlugins.length>0&&o(document).trigger("display.foswikiUpdates"))},i.prototype.displayPluginInfo=function(){var i;o(".foswikiUpdatesMessage").remove(),i=o("#foswikiUpdatesTmpl").render([{nrPlugins:this.outdatedPlugins.length,outdatedPlugins:this.outdatedPlugins.sort().join(", "),cookieExpires:this.options.cookieExpires,configureUrl:this.options.configureUrl}]),o(i).prependTo("body").fadeIn()},o(function(){e=e||new i})}(jQuery);