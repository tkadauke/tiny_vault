# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def bread_crumb
    items = [%{<a href="/">#{I18n.t('breadcrumb.home')}</a>}]
    sofar = ''
    elements = request.fullpath.split('?').first.split('/')
    parent_model = nil
    for i in 1...elements.size
      sofar += '/' + elements[i]
      
      parent_model, link_text = begin
        next_model = if parent_model
          parent_model.instance_eval("#{elements[i - 1]}.from_param!('#{elements[i]}')")
        else
          eval("#{elements[i - 1].singularize.camelize}.from_param!('#{elements[i]}')")
        end
        [next_model, next_model.respond_to?(:name) ? next_model.name : next_model.to_param]
      rescue Exception => e
        [parent_model, I18n.t("breadcrumb.#{elements[i]}")]
      end
      
      if sofar == request.path
        items << "<strong>"  + link_text + '</strong>'
      else
        items << "<a href='#{sofar}'>"  + link_text + '</a>'
      end
    end
    
    content_tag :ul do
      items.collect { |item| content_tag(:li) { item.html_safe } }.join.html_safe
    end
  end
  
  def revision_link
    build = TinyVault::Version.build
    if build == 'unknown'
      I18n.t('layouts.unknown_build')
    else
      link_to(build[0..7], "http://github.com/tkadauke/tiny_vault/commit/#{TinyVault::Version.build}")
    end
  end
  
  def bookmarklet_url
    "javascript:script=document.createElement('script');script.setAttribute('src','http://#{request.host_with_port}/javascripts/fill.js');script.setAttribute('type','text/javascript');document.body.appendChild(script);void(0);"
  end
end
