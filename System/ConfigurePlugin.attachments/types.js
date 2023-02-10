var Types={};(function($){"use strict";Types.BaseType=Class.extend({null_if:null,init:function(e){this.spec=e},createUI:function(e){var t,s,i,r,u,n=this.spec.current_value;return void 0===n&&(n=""),this.spec.SIZE&&(t=this.spec.SIZE.match(/^\s*(\d+)x(\d+)(\s|$)/))?(s=t[1],i=t[2],r=(r=void 0===n?"":n).replace(/&/g,"&amp;"),this.$ui=$('<textarea id="'+_id_ify(this.spec.keys)+'" rows="'+i+'" cols="'+s+'" class="foswikiTextArea">'+r+"</textarea>")):(u=80,this.spec.SIZE&&(t=this.spec.SIZE.match(/^\s*(\d+)(\s|$)/))&&(u=t[1]),this.$ui=$('<input type="text" id="'+_id_ify(this.spec.keys)+'" size="'+u+'"/>'),this.useVal(n)),this.spec.SPELLCHECK&&this.$ui.prop("spellcheck",!0),void 0!==e&&this.$ui.change(e),this.$ui},useVal:function(e){this.$ui.val(e)},currentValue:function(){return null!==this.null_if&&this.null_if()?null:this.$ui.val()},commitVal:function(){this.spec.current_value=this.currentValue()},restoreCurrentValue:function(){this.useVal(this.spec.current_value)},restoreDefaultValue:function(){this.useVal(this.spec.default)},isModified:function(){var e=this.spec.current_value;return void 0===e&&(e=null===this.null_if?"":null),this.currentValue()!=e},isDefault:function(){return this.currentValue()==this.spec.default}}),Types.STRING=Types.BaseType.extend({restoreDefaultValue:function(){var e=this.spec.default;e="undef"===e?null:e.replace(/^\s*(["'])(.*)\1\s*$/,"$2"),this.useVal(e)},isDefault:function(){var e=this.spec.default;return"string"==typeof e&&/^\s*'.*'\s*$/.test(e)&&(e=(e=e.replace(/^\s*'(.*)'\s*$/,"$1")).replace(/\'/g,"'")),this.currentValue()===e}}),Types.BOOLEAN=Types.BaseType.extend({createUI:function(e){return this.$ui=$('<input type="checkbox" id="'+_id_ify(this.spec.keys)+'" />'),void 0!==e&&this.$ui.change(e),void 0===this.spec.current_value||"0"==this.spec.current_value?this.spec.current_value=0:"1"==this.spec.current_value&&(this.spec.current_value=1),0!==this.spec.current_value&&this.$ui.prop("checked",!0),this.spec.extraClass&&this.$ui.addClass(this.spec.extraClass),this.$ui},currentValue:function(){return this.$ui[0].checked?1:0},isModified:function(){return this.currentValue()!=this.spec.current_value},isDefault:function(){var a=this.currentValue(),b=eval(this.spec.default);return a==b},useVal:function(e){void 0===e||"0"==e||"$FALSE"==e?e=!1:"1"==e&&(e=!0),this.$ui.prop("checked",e)}}),Types.PASSWORD=Types.STRING.extend({createUI:function(e){return this._super(e),this.$ui.attr("type","password"),this.$ui.attr("autocomplete","new-password"),this.$ui}}),Types.REGEX=Types.STRING.extend({restoreDefaultValue:function(){var e=this.spec.default;e=(e="undef"===e?null:e.replace(/^\s*(["'])(.*)\1\s*$/,"$2")).replace(/\\\\\\/,"\\"),this.useVal(e)},isDefault:function(){var e=this.spec.default;return"string"==typeof e&&/^\s*'.*'\s*$/.test(e)&&(e=(e=(e=e.replace(/^\s*'(.*)'\s*$/,"$1")).replace(/\'/g,"'")).replace(/\\\\\\/,"\\")),this.currentValue()===e}}),Types.deep_equals=function(e,t){if(e===t)return!0;if(null==e||null==t)return!1;if(e.constructor!==t.constructor)return!1;if(e.valueOf()===t.valueOf())return!0;if(Array.isArray(e)&&e.length!==t.length)return!1;if(!(e instanceof Object&&t instanceof Object))return!1;var s=Object.keys(e);return Object.keys(t).every((function(e){return-1!==s.indexOf(e)}))&&s.every((function(s){return Types.deep_equals(e[s],t[s])}))},Types.PERL=Types.BaseType.extend({createUI:function(e){return this.spec.SIZE&&this.spec.SIZE.match(/\b(\d+)x(\d+)\b/)||(this.spec.SIZE="80x20"),this._super(e)},isDefault:function(){var a=this.currentValue(),b=this.spec.default,av,bv;a=null==a?null:a.trim(),b=null==b?null:b.trim();try{av=eval(a),bv=eval(b)}catch(e){av=null,bv=null}return null!==av&&null!==bv?Types.deep_equals(av,bv):a===b}}),Types.XML=Types.BaseType.extend({createUI:function(e){return this.spec.SIZE&&this.spec.SIZE.match(/\b(\d+)x(\d+)\b/)||(this.spec.SIZE="80x20"),this._super((function(t){var s=$(this).val().trim();""!=s&&((new DOMParser).parseFromString(s,"text/xml").getElementsByTagName("parsererror").length?($(this).css("background-color","yellow"),alert('"'+s+'" is not a valid XML document')):($(this).css("background-color",""),$(this).val(s),e.call(this,t)))}))}}),Types.CERT=Types.BaseType.extend({createUI:function(e){return this.spec.SIZE&&this.spec.SIZE.match(/\b(\d+)x(\d+)\b/)||(this.spec.SIZE="80x20"),this._super((function(t){var s=$(this).val().trim();""!=s&&(/^-----BEGIN CERTIFICATE-----[\s\S]*-----END CERTIFICATE-----$/.test(s)||/^-----BEGIN PRIVATE KEY-----[\s\S]*-----END PRIVATE KEY-----$/.test(s)?($(this).css("background-color",""),$(this).val(s),e.call(this,t)):($(this).css("background-color","yellow"),alert('"'+s+'" is not a valid base64 encoded certificate')))}))}}),Types.NUMBER=Types.BaseType.extend({createUI:function(e){return this._super((function(t){var s=$(this).val();/^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/.test(s)?($(this).css("background-color",""),e.call(this,t)):($(this).css("background-color","yellow"),alert('"'+s+'" is not a valid number'))}))}}),Types.OCTAL=Types.NUMBER.extend({createUI:function(e){return this._super((function(t){var s=$(this).val();/^[0-7]+$/.test(s)?($(this).css("background-color",""),e.call(this,t)):($(this).css("background-color","yellow"),alert('"'+s+'" is not a valid octal number'))}))}}),Types.PATHINFO=Types.STRING.extend({createUI:function(e){return this._super(e),this.$ui.prop("readonly",!0),this.$ui}}),Types.PATH=Types.STRING.extend({}),Types.URL=Types.STRING.extend({}),Types.URILIST=Types.STRING.extend({}),Types.URLPATH=Types.STRING.extend({}),Types.DATE=Types.STRING.extend({}),Types.COMMAND=Types.STRING.extend({}),Types.EMAILADDRESS=Types.STRING.extend({}),Types.NULL=Types.BaseType.extend({createUI:function(e){return this._super(e),this.$ui.prop("readonly",!0),this.$ui.prop("disabled",!0),this.$ui.attr("size","1"),this.$ui}}),Types.BUTTON=Types.BaseType.extend({createUI:function(){return this.$ui=$('<a href="'+this.spec.uri+'">'+this.spec.title+"</a>"),this.$ui.button(),this.$ui},useVal:function(){}}),Types.SELECT=Types.BaseType.extend({_getSel:function(e,t){var s,i,r={};if(void 0!==e)if(t)for(s=e.split(","),i=0;i<s.length;i++)r[s[i]]=!0;else r[e]=!0;return r},createUI:function(e){var t,s,i,r,u,n=1;if(this.spec.SIZE&&(t=this.spec.SIZE.match(/\b(\d+)\b/))&&(n=t[0]),this.$ui=$('<select id="'+_id_ify(this.spec.keys)+'" size="'+n+'" class="foswikiSelect" />'),void 0!==e&&this.$ui.change(e),this.spec.MULTIPLE&&this.$ui.prop("multiple",!0),void 0!==this.spec.select_from)for(s=this._getSel(this.spec.current_value,this.spec.MULTIPLE),i=0;i<this.spec.select_from.length;i++)r=this.spec.select_from[i],u=$("<option>"+r+"</option>"),s[r]&&u.prop("selected",!0),this.$ui.append(u);return this.$ui},useVal:function(e){e=e.replace(/^\s*(["'])(.*?)\1\s*/,"$2");var t,s=this._getSel(e),i=this.spec.select_from;void 0!==i&&(t=0,this.$ui.find("option").each((function(){var e=i[t++];s[e]?$(this).prop("selected",!0):$(this).prop("selected",!1)})))},isDefault:function(){var e=this.currentValue(),t=this.spec.default;return(e=null==e?null:e.trim())===(t=(t=null==t?null:t.trim()).replace(/^\s*(["'])(.*?)\1\s*/,"$2"))}}),Types.SELECTCLASS=Types.SELECT.extend({})})(jQuery);
