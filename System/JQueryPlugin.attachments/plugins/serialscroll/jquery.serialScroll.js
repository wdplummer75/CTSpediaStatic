/*!
 * jQuery.serialScroll
 * Copyright (c) 2007-2015 Ariel Flesler - aflesler<a>gmail<d>com | http://flesler.blogspot.com
 * Licensed under MIT.
 * @projectDescription Animated scrolling of series with jQuery
 * @author Ariel Flesler
 * @version 1.3.1
 * https://github.com/flesler/jquery.serialScroll
 */
!function(t){var n=".serialScroll",e=t.serialScroll=function(n){return t(window).serialScroll(n)};e.defaults={duration:1e3,axis:"x",event:"click",start:0,step:1,lock:!0,cycle:!0,constant:!0},t.fn.serialScroll=function(o){return this.each((function(){var i,r=t.extend({},e.defaults,o),a=r.event,c=r.step,u=r.lazy,l=r.target?this:document,s=t(r.target||this,l),f=s[0],d=r.items,v=r.start,h=r.interval,p=r.navigation;function g(t){t.data+=v,x(t,this)}function x(n,e){t.isNumeric(e)||(e=n.data);var o,a=n.type,u=r.exclude?S().slice(0,-r.exclude):S(),l=u.length-1,f=u[e],d=r.duration;if(a&&n.preventDefault(),h&&(y(),i=setTimeout(m,r.interval)),!f){if(v!==(o=e<0?0:l))e=o;else{if(!r.cycle)return;e=l-o}f=u[e]}!f||r.lock&&s.is(":animated")||a&&r.onBefore&&!1===r.onBefore(n,f,s,S(),e)||(r.stop&&s.stop(!0),r.constant&&(d=Math.abs(d/c*(v-e))),s.scrollTo(f,d,r),_("notify",e))}function m(){_("next")}function y(){clearTimeout(i)}function S(){return t(d,f)}function _(t){s.trigger(t+n,[].slice.call(arguments,1))}function b(n){if(t.isNumeric(n))return n;for(var e,o=S();-1===(e=o.index(n))&&n!==f;)n=n.parentNode;return e}delete r.step,delete r.start,f&&(u||(d=S()),(r.force||h)&&x({},v),t(r.prev||[],l).on(a,-c,g),t(r.next||[],l).on(a,c,g),f._bound_||s.on("prev"+n,-c,g).on("next"+n,c,g).on("goto"+n,x),h&&s.on("start"+n,(function(t){h||(y(),h=!0,m())})).on("stop"+n,(function(){y(),h=!1})),s.on("notify"+n,(function(t,n){var e=b(n);e>-1&&(v=e)})),f._bound_=!0,r.jump&&(u?s:S()).on(a,(function(t){x(t,b(t.target))})),p&&(p=t(p,l).on(a,(function(t){t.data=Math.round(S().length/p.length)*p.index(this),x(t,this)}))))}))}}(jQuery);
