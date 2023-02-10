/*!
	Slimbox v2.05 - The ultimate lightweight Lightbox clone for jQuery
	(c) 2007-2013 Christophe Beyls <http://www.digitalia.be>
	MIT-style license.
*/
!function(i){var e,t,n,o,a,l,r,s,c,d,u,h,f,p,y,g,m,v,b,w=i(window),x=-1,k=!window.XMLHttpRequest,D=[],L=(document.documentElement,{}),I=new Image,T=new Image;function z(){var e=w.scrollLeft(),t=w.width();i([u,g]).css("left",e+t/2),l&&i(d).css({left:e,top:w.scrollTop(),width:t,height:w.height()})}function H(e){e?i("object").add(k?"select":"embed").each((function(i,e){D[i]=[e,e.style.visibility],e.style.visibility="hidden"})):(i.each(D,(function(i,e){e[0].style.visibility=e[1]})),D=[]);var t=e?"bind":"unbind";w[t]("scroll resize",z),i(document)[t]("keydown",K)}function K(t){var n=t.which,o=i.inArray;return o(n,e.closeKeys)>=0?A():o(n,e.nextKeys)>=0?C():o(n,e.previousKeys)>=0?F():null}function F(){return E(o)}function C(){return E(a)}function E(i){return i>=0&&(n=t[x=i][0],o=(x||(e.loop?t.length:0))-1,a=(x+1)%t.length||(e.loop?0:-1),W(),u.className="lbLoading",(L=new Image).onload=N,L.src=n),!1}function N(){u.className="",i(h).css({backgroundImage:"url("+n+")",visibility:"hidden",display:""}),i(f).width(L.width),i([f,p,y]).height(L.height),i(v).html(t[x][1]||""),i(b).html((t.length>1&&e.counterText||"").replace(/{x}/,x+1).replace(/{y}/,t.length)),o>=0&&(I.src=t[o][0]),a>=0&&(T.src=t[a][0]),s=h.offsetWidth,c=h.offsetHeight;var l=Math.max(0,r-c/2);u.offsetHeight!=c&&i(u).animate({height:c,top:l},e.resizeDuration,e.resizeEasing),u.offsetWidth!=s&&i(u).animate({width:s,marginLeft:-s/2},e.resizeDuration,e.resizeEasing),i(u).queue((function(){i(g).css({width:s,top:l+c,marginLeft:-s/2,visibility:"hidden",display:""}),i(h).css({display:"none",visibility:"",opacity:""}).fadeIn(e.imageFadeDuration,O)}))}function O(){o>=0&&i(p).show(),a>=0&&i(y).show(),i(m).css("marginTop",-m.offsetHeight).animate({marginTop:0},e.captionAnimationDuration),g.style.visibility=""}function W(){L.onload=null,L.src=I.src=T.src=n,i([u,h,m]).stop(!0),i([p,y,h,g]).hide()}function A(){return x>=0&&(W(),x=o=a=-1,i(u).hide(),i(d).stop().fadeOut(e.overlayFadeDuration,H)),!1}i((function(){i("body").append(i([d=i('<div id="lbOverlay" />').click(A)[0],u=i('<div id="lbCenter" />')[0],g=i('<div id="lbBottomContainer" />')[0]]).css("display","none")),h=i('<div id="lbImage" />').appendTo(u).append(f=i('<div style="position: relative;" />').append([p=i('<a id="lbPrevLink" href="#" />').click(F)[0],y=i('<a id="lbNextLink" href="#" />').click(C)[0]])[0])[0],m=i('<div id="lbBottom" />').appendTo(g).append([i('<a id="lbCloseLink" href="#" />').click(A)[0],v=i('<div id="lbCaption" />')[0],b=i('<div id="lbNumber" />')[0],i('<div style="clear: both;" />')[0]])[0]})),i.slimbox=function(n,o,a){return e=i.extend({loop:!1,overlayOpacity:.8,overlayFadeDuration:400,resizeDuration:400,resizeEasing:"swing",initialWidth:250,initialHeight:250,imageFadeDuration:400,captionAnimationDuration:400,counterText:"Image {x} of {y}",closeKeys:[27,88,67],previousKeys:[37,80],nextKeys:[39,78]},a),"string"==typeof n&&(n=[[n,o]],o=0),r=w.scrollTop()+w.height()/2,s=e.initialWidth,c=e.initialHeight,i(u).css({top:Math.max(0,r-c/2),width:s,height:c,marginLeft:-s/2}).show(),(l=k||d.currentStyle&&"fixed"!=d.currentStyle.position)&&(d.style.position="absolute"),i(d).css("opacity",e.overlayOpacity).fadeIn(e.overlayFadeDuration),z(),H(1),t=n,e.loop=e.loop&&t.length>1,E(o)},i.fn.slimbox=function(e,t,n){t=t||function(i){return[i.href,i.title]},n=n||function(){return!0};var o=this;return o.unbind("click").click((function(){var a,l,r=this,s=0,c=0;for(l=(a=i.grep(o,(function(i,e){return n.call(r,i,e)}))).length;c<l;++c)a[c]==r&&(s=c),a[c]=t(a[c],c);return i.slimbox(a,s,e)}))}}(jQuery);