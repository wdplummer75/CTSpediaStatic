/*!
 * jQuery.localScroll
 * Copyright (c) 2007-2015 Ariel Flesler - aflesler<a>gmail<d>com | http://flesler.blogspot.com
 * Licensed under MIT
 * http://flesler.blogspot.com/2007/10/jquerylocalscroll-10.html
 * @author Ariel Flesler
 * @version 1.4.0
 */
!function(e){"function"==typeof define&&define.amd?define(["jquery"],e):e(jQuery)}((function(e){var t=location.href.replace(/#.*/,""),n=e.localScroll=function(t){e("body").localScroll(t)};function o(t,n,o){var i=n.hash.slice(1),a=document.getElementById(i)||document.getElementsByName(i)[0];if(a){t&&t.preventDefault();var l=e(o.target);if(!(o.lock&&l.is(":animated")||o.onBefore&&!1===o.onBefore(t,a,l))){if(o.stop&&l.stop(!0),o.hash){var r=a.id===i?"id":"name",s=e("<a> </a>").attr(r,i).css({position:"absolute",top:e(window).scrollTop(),left:e(window).scrollLeft()});a[r]="",e("body").prepend(s),location.hash=n.hash,s.remove(),a[r]=i}l.scrollTo(a,o).trigger("notify.serialScroll",[a])}}}return(n.defaults={duration:1e3,axis:"y",event:"click",stop:!0,target:window},e.fn.localScroll=function(i){return(i=e.extend({},n.defaults,i)).hash&&location.hash&&(i.target&&window.scrollTo(0,0),o(0,location,i)),i.lazy?this.on(i.event,"a,area",(function(e){a.call(this)&&o(e,this,i)})):this.find("a,area").filter(a).bind(i.event,(function(e){o(e,this,i)})).end().end();function a(){return!!this.href&&!!this.hash&&this.href.replace(this.hash,"")===t&&(!i.filter||e(this).is(i.filter))}},n.hash=function(){},n)}));
