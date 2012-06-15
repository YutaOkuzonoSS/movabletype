(function(a){a.each(["plugin","advanced"],function(){tinymce.ScriptLoader.add(tinymce.PluginManager.urls.mt+"/langs/"+this+".js")});tinymce.Editor.prototype.addMTButton=function(d,e){var c=this;var f={};var b=e.onclickFunctions;if(b){e.onclick=function(){var h=c.mtEditorStatus.mode;var g=b[h];if(typeof(g)=="string"){c.mtProxies[h].execCommand(g)}else{g.apply(c,arguments)}if(h=="source"){c.onMTSourceButtonClick.dispatch(c,c.controlManager)}};for(k in b){f[k]=1}}else{f={wysiwyg:1,source:1}}if(!e.isSupported){e.isSupported=function(i,h){if(!f[i]){return false}if(b&&i=="source"){var g=b[i];if(typeof(g)=="string"){return c.mtProxies.source.isSupported(g,h)}else{return true}}else{return true}}}if(typeof(c.mtButtons)=="undefined"){c.mtButtons={}}c.mtButtons[d]=e;return c.addButton(d,e)};tinymce.create("tinymce.ui.MTTextButton:tinymce.ui.Button",{renderHTML:function(){var e=tinymce.DOM;var f=this.classPrefix,d=this.settings,c,b;b=e.encode(d.label||"");c='<a role="button" id="'+this.id+'" href="javascript:;" class="mceMTTextButton '+f+" "+f+"Enabled "+d["class"]+(b?" "+f+"Labeled":"")+'" onmousedown="return false;" onclick="return false;" aria-labelledby="'+this.id+'_voice" title="'+e.encode(d.title)+'">';c+=d.text;c+="</a>";return c}});tinymce.create("tinymce.plugins.MovableType",{buttonSettings:"",initButtonSettings:function(b){var e=this;e.buttonIDs={};var d={source:{},wysiwyg:{}};var c=1;a.each(["common","source","wysiwyg"],function(h,f){var l="plugin_mt_"+f+"_buttons";for(var g=1;b.settings[l+g];g++){e.buttonSettings+=(e.buttonSettings?",":"")+b.settings[l+g];b.settings["theme_advanced_buttons"+c]=b.theme.settings["theme_advanced_buttons"+c]=b.settings[l+g];if(f=="common"){d.source[c-1]=d.wysiwyg[c-1]=1}else{d[f][c-1]=1}c++}});return d},init:function(h,g){var e=this;var p=h.id;var c=p.length;var r=a("#blog-id").val()||0;var d={};var o=[];var q=null;var f={};var u=this.initButtonSettings(h);var l={};h.mtProxies=d;h.mtEditorStatus={mode:"wysiwyg",format:"richtext"};function s(x,w){var v=x+"-"+w;if(!f[v]){f[v]={};a.each(h.mtButtons,function(y,z){if(z.isSupported(x,w)){f[v][y]=z}})}return f[v]}function b(){var v=h.mtEditorStatus;a.each(o,function(z,y){q.find(".mce_"+y).css({display:""}).removeClass("mce_mt_button_hidden");h.controlManager.setDisabled(this,false)});o=[];var w=s(v.mode,v.format);function x(y){if(!w[y]){q.find(".mce_"+y).css({display:"none"}).addClass("mce_mt_button_hidden");o.push(y)}}if(v.mode=="source"){d.source.setFormat(v.format);a.each(h.controlManager.controls,function(y,z){if(!z.classPrefix){return}x(y.substr(c+1))})}else{a.each(h.mtButtons,function(y,z){x(y)})}a("#"+p+"_toolbargroup > span > table").each(function(y){if(u[v.mode][y]){a(this).show()}else{a(this).hide()}})}function t(w,v){a.fn.mtDialog.open(ScriptURI+"?__mode="+w+"&amp;"+v)}function i(v){a.each(h.windowManager.windows,function(y,x){var z=x.iframeElement;a("#"+z.id).load(function(){var A=this.contentWindow;var w={"$contents":a(this).contents(),window:A};v(w,function(){A.tinyMCEPopup.close();if(tinymce.isWebKit){a("#convert_breaks").focus()}d.source.focus()})})})}function n(x,v){function w(){var y=a(this);d.source.execCommand("createLink",null,y.find("#href").val(),{target:y.find("#target_list").val(),title:y.find("#linktitle").val()});v()}x["$contents"].find("form").attr("onsubmit","").submit(w);if(!d.source.isSupported("createLink",h.mtEditorStatus.format,"target")){x["$contents"].find("#targetlistlabel").closest("tr").hide()}}function m(w,v){a.each(h.mtButtons,function(x,y){var z;if(y.onclickFunctions&&(z=y.onclickFunctions["source"])&&(typeof(z)=="string")&&(e.buttonSettings.indexOf(x)!=-1)){l[x]=z}})}function j(w,v){a.each(l,function(x,y){v.setActive(x,w.mtProxies.source.isStateActive(y))})}h.onInit.add(function(){q=a(h.getContainer());b();m();h.theme.resizeBy(0,0)});h.addCommand("mtGetStatus",function(){return h.mtEditorStatus});h.addCommand("mtSetStatus",function(v){a.extend(h.mtEditorStatus,v);b()});h.addCommand("mtGetProxies",function(){return d});h.addCommand("mtSetProxies",function(v){a.extend(d,v)});h.addButton("mt_insert_html",{title:"mt.insert_html",onclick:function(){h.windowManager.open({file:g+"/insert_html.html",width:430,height:335,inline:1},{plugin_url:g})}});h.addMTButton("mt_insert_image",{title:"mt.insert_image",onclick:function(){t("dialog_list_asset","_type=asset&amp;edit_field="+p+"&amp;blog_id="+r+"&amp;dialog_view=1&amp;filter=class&amp;filter_val=image")}});h.addMTButton("mt_insert_file",{title:"mt.insert_file",onclick:function(){t("dialog_list_asset","_type=asset&amp;edit_field="+p+"&amp;blog_id="+r+"&amp;dialog_view=1")}});h.addMTButton("mt_source_bold",{title:"mt.source_bold",text:"strong",mtButtonClass:"text",onclickFunctions:{source:"bold"}});h.addMTButton("mt_source_italic",{title:"mt.source_italic",text:"em",mtButtonClass:"text",onclickFunctions:{source:"italic"}});h.addMTButton("mt_source_blockquote",{title:"mt.source_blockquote",text:"blockquote",mtButtonClass:"text",onclickFunctions:{source:"blockquote"}});h.addMTButton("mt_source_unordered_list",{title:"mt.source_unordered_list",text:"ul",mtButtonClass:"text",onclickFunctions:{source:"insertUnorderedList"}});h.addMTButton("mt_source_ordered_list",{title:"mt.source_ordered_list",text:"ol",mtButtonClass:"text",onclickFunctions:{source:"insertOrderedList"}});h.addMTButton("mt_source_list_item",{title:"mt.source_list_item",text:"li",mtButtonClass:"text",onclickFunctions:{source:"insertListItem"}});h.addMTButton("mt_source_link",{title:"mt.insert_link",onclickFunctions:{source:function(w,v,x){tinymce._setActive(h);this.theme._mceLink.apply(this.theme);i(n)}}});h.addMTButton("mt_source_mode",{title:"mt.source_mode",onclickFunctions:{wysiwyg:function(){h.execCommand("mtSetFormat","none.tinymce_temp")},source:function(){h.execCommand("mtSetFormat","richtext")}}});if(!h.onMTSourceButtonClick){h.onMTSourceButtonClick=new tinymce.util.Dispatcher(h)}h.onMTSourceButtonClick.add(j);h.onNodeChange.add(function(x,v,B,A,w){var y=x.mtEditorStatus;if(x.mtEditorStatus.mode=="source"&&x.mtEditorStatus.format!="none.tinymce_temp"){a("#"+p+"_mt_source_mode").css("display","none")}else{a("#"+p+"_mt_source_mode").css("display","")}var z=x.mtEditorStatus.mode=="source"&&x.mtEditorStatus.format=="none.tinymce_temp";v.setActive("mt_source_mode",z);if(!x.mtProxies.source){return}j(x,x.controlManager)})},createControl:function(d,b){var g=b.editor;var h=g.buttons[d];if((d=="mt_insert_image")||(d=="mt_insert_file")){if(!this.buttonIDs[d]){this.buttonIDs[d]=[]}var i=d+"_"+this.buttonIDs[d].length;this.buttonIDs[d].push(i);return b.createButton(i,a.extend({},h,{"class":"mce_"+d}))}if(h&&h.mtButtonClass){var f,c,e;switch(h.mtButtonClass){case"text":c=tinymce.ui.MTTextButton;break;default:throw new Error("Not implemented:"+h.mtButtonClass)}if(b._cls.button){e=b._cls.button}b._cls.button=c;f=b.createButton(d,a.extend({},h));if(e!=="undefined"){b._cls.button=e}return f}return null},getInfo:function(){return{longname:"MovableType",author:"Six Apart, Ltd",authorurl:"",infourl:"",version:"1.0"}}});tinymce.PluginManager.add("mt",tinymce.plugins.MovableType)})(jQuery);