defmodule Credo.CLI.Command.ReportCard.Output.Html do
  @moduledoc false

  alias Credo.Execution

  def print_before_info(_source_files, _exec), do: nil

  def print_after_info(_source_files, exec, _time_load, _time_run) do
    exec
    |> Execution.get_issues()
    |> print_issues()
  end

  alias Credo.Service.SourceFileLines

  @head_links """
  <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.1.1/jquery.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.15.0/components/prism-core.min.js" data-manual></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.15.0/plugins/line-numbers/prism-line-numbers.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.15.0/plugins/line-highlight/prism-line-highlight.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.15.0/components/prism-elixir.min.js"></script>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.15.0/themes/prism.min.css" />
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.15.0/plugins/line-numbers/prism-line-numbers.min.css" />
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.15.0/plugins/line-highlight/prism-line-highlight.min.css" />
  """

  @inline_styles """
  <style>
    /**
    * prism.js Code Climate theme based on Coy theme
    */

    code[class*="language-"],
    pre[class*="language-"] {
      color: black;
      font-family: Consolas, 'Bitstream Vera Sans Mono', Monaco, Courier, monospace;
      direction: ltr;
      text-align: left;
      white-space: pre;
      word-spacing: normal;
      word-break: normal;
      tab-size: 4;
      hyphens: none;
      font-size: 12px;
    }

    pre[class*="language-"] {
      position:relative;
      background-color: #fdfdfd;
      background-image: linear-gradient(rgba(69, 142, 209, 0.0) 50%, rgba(69, 142, 209, 0.04) 50%);
      background-size: 3em 3em;
      background-origin: content-box;
      /*overflow: hidden;
      border: 1px solid #dde8ef;*/
      margin-top: 1em;
    }

    pre > code[class*="language-"] {
      display: block;
      z-index: 100;
    }

    /* Inline code */
    :not(pre) > code[class*="language-"] {
      position:relative;
      padding: .2em;
      -webkit-border-radius: 0.3em;
      -moz-border-radius: 0.3em;
      -ms-border-radius: 0.3em;
      -o-border-radius: 0.3em;
      border-radius: 0.3em;
    }

    .token.punctuation {
      font-weight: bold;
    }

    .token.operator {
      font-weight: bold;
    }

    .token.keyword {
      font-weight: bold;
    }

    .token.class-name {
      font-weight: bold;
    }

    .token.important {
      font-weight: normal;
    }

    .token.entity {
      cursor: help;
    }

    .token.attribute {
      color: #46b1ae;
    }

    .namespace {
      opacity: .7;
    }

    pre.line-numbers {
      position: relative;
      padding-left: 40px;
      counter-reset: linenumber;
    }

    pre.line-numbers > code {
      position: relative;
      padding-left: 4px;
    }

    .line-numbers .line-numbers-rows {
      position: absolute;
      pointer-events: none;
      top: 0;
      font-size: 100%;
      left: -3.8em;
      width: 3.8em; /* works for line-numbers below 1000 lines */
      letter-spacing: -1px;
      padding-top: 1px;
      user-select: none;
      background-color: #f1f1f1;
      color: #757575;
    }

    .line-numbers-rows > span {
      pointer-events: none;
      display: block;
      counter-increment: linenumber;
    }

    .line-numbers-rows > span:before {
      content: counter(linenumber);
      color: #999;
      display: block;
      padding-right: 0.8em;
      text-align: right;
    }
  </style>
  <style>
    /**
    * Report styles
    */

    html, body {
      font-size: 15px;
      line-height: 1.333;
      background: #f6f6f5;
      color: #323543;
      font-family: "BentonSans", helvetica, arial, sans-serif;
      font-style: normal;
      font-weight: normal;
      min-width: 960px;
      margin: 0;
      padding: 0;
    }
    a {
      color:#007dce;
      text-decoration: none;
    }
    a:hover {
      color:#005e9b;
      text-decoration: underline;
    }
    .container {
      width: 960px;
      margin: 0 auto;
    }
    #top {
      color: #fff;
      background: #323543;
        padding: 5px 0;
    }
    #top h1 {
      display: inline-block;
      font-size: 16px;
      font-weight: normal;
      margin: 0;
      vertical-align: middle;
    }
    #top h1::before {
      content: '/ ';
    }
    nav ul, #smells {
      margin: 0;
      padding: 0;
    }
    nav li {
      list-style: none;
      padding: 10px 20px;
      color: #5e637d;
      position: relative;
      display: inline-block;
    }
    nav li::after {
      content: '';
      position: absolute;
      border-bottom: 8px solid #fff;
      border-left: 8px solid transparent;
      border-right: 8px solid transparent;
      bottom: 0px;
      left: 50%;
      margin-left: -8px;
    }
    #main-container {
      background: #fff;
      padding: 20px;
      overflow: hidden;
      position: relative;
    }
    .issue-filters {
      float: right;
      width: 200px;
    }
    .issue-filters label,
    .issue-filters select {
      display: block;
      width: 100%;
    }
    .issue-filters label {
      margin-top: 10px;
    }
    #smells {
      /* max-width: 680px; */
    }
    #smells > li {
      list-style: none;
      border-bottom: 1px solid #f6f6f5;
      padding-top: 10px;
      padding-bottom: 20px;
    }
    #smells > li:last-of-type {
      border-bottom: 0px none;
      padding-bottom: 0;
    }
    #smells > li > h2 {
      font-weight: bold;
      margin-top: 0;
      font-size: inherit;
    }

    #smells .code {
      position: relative;
      /* overflow: hidden; */
      border-radius: 3px;
      border: 1px solid #dde8ef;
      height: 6em;
      margin: 10px 0;
    }
    #smells .code > pre {
      visibility: hidden;
    }
    #smells .code > pre,
    #smells .code > pre .line-highlight {
      margin-bottom: 0;
      margin-top: 0;
      padding-bottom: 0;
      padding-top: 0;
    }

    .found-in {
      font-size: 12px;
      line-height: 20px;
      color: #9999a1;
      margin-top: 10px;
      margin-bottom: 15px;
    }
    .found-in a {
      color: #35b0ff;
    }
    ::-webkit-details-marker {display: none;}
    details summary {
      display: block;
    }
    details summary::before {
      content: "► ";

    }
    details[open] summary::before {
      content: "▼ ";
    }

    #filtered-out-message {
      display: none;
      text-align: center;
      position: absolute;
      left: 0;
      width: 720px;
      text-align: center;
      top: 50%;
      margin-top: -1em;
      line-height: 2em;
    }

    #no-issues-message {
      text-align: center;
    }
    #no-issues-message::before {
      content: "🎉";
      font-size: 3em;
        display: block;
    }
  </style>
  """

  @table_scripts """
  <script>
    // StupidTable.min.js
    // https://github.com/joequery/Stupid-Table-Plugin
    (function(c){c.fn.stupidtable=function(a){return this.each(function(){var b=c(this);a=a||{};a=c.extend({},c.fn.stupidtable.default_sort_fns,a);b.data("sortFns",a);b.stupidtable_build();b.on("click.stupidtable","thead th",function(){c(this).stupidsort()});b.find("th[data-sort-onload=yes]").eq(0).stupidsort()})};c.fn.stupidtable.default_settings={should_redraw:function(a){return!0},will_manually_build_table:!1};c.fn.stupidtable.dir={ASC:"asc",DESC:"desc"};c.fn.stupidtable.default_sort_fns={"int":function(a,
    b){return parseInt(a,10)-parseInt(b,10)},"float":function(a,b){return parseFloat(a)-parseFloat(b)},string:function(a,b){return a.toString().localeCompare(b.toString())},"string-ins":function(a,b){a=a.toString().toLocaleLowerCase();b=b.toString().toLocaleLowerCase();return a.localeCompare(b)}};c.fn.stupidtable_settings=function(a){return this.each(function(){var b=c(this),f=c.extend({},c.fn.stupidtable.default_settings,a);b.stupidtable.settings=f})};c.fn.stupidsort=function(a){var b=c(this),f=b.data("sort")||
    null;if(null!==f){var d=b.closest("table"),e={$th:b,$table:d,datatype:f};d.stupidtable.settings||(d.stupidtable.settings=c.extend({},c.fn.stupidtable.default_settings));e.compare_fn=d.data("sortFns")[f];e.th_index=h(e);e.sort_dir=k(a,e);b.data("sort-dir",e.sort_dir);d.trigger("beforetablesort",{column:e.th_index,direction:e.sort_dir,$th:b});d.css("display");setTimeout(function(){d.stupidtable.settings.will_manually_build_table||d.stupidtable_build();var a=l(e),a=m(a,e);if(d.stupidtable.settings.should_redraw(e)){d.children("tbody").append(a);
    var a=e.$table,c=e.$th,f=c.data("sort-dir");a.find("th").data("sort-dir",null).removeClass("sorting-desc sorting-asc");c.data("sort-dir",f).addClass("sorting-"+f);d.trigger("aftertablesort",{column:e.th_index,direction:e.sort_dir,$th:b});d.css("display")}},10);return b}};c.fn.updateSortVal=function(a){var b=c(this);b.is("[data-sort-value]")&&b.attr("data-sort-value",a);b.data("sort-value",a);return b};c.fn.stupidtable_build=function(){return this.each(function(){var a=c(this),b=[];a.children("tbody").children("tr").each(function(a,
    d){var e={$tr:c(d),columns:[],index:a};c(d).children("td").each(function(a,b){var d=c(b).data("sort-value");"undefined"===typeof d&&(d=c(b).text(),c(b).data("sort-value",d));e.columns.push(d)});b.push(e)});a.data("stupidsort_internaltable",b)})};var l=function(a){var b=a.$table.data("stupidsort_internaltable"),f=a.th_index,d=a.$th.data("sort-multicolumn"),d=d?d.split(","):[],e=c.map(d,function(b,d){var c=a.$table.find("th"),e=parseInt(b,10),f;e||0===e?f=c.eq(e):(f=c.siblings("#"+b),e=c.index(f));
    return{index:e,$e:f}});b.sort(function(b,c){for(var d=e.slice(0),g=a.compare_fn(b.columns[f],c.columns[f]);0===g&&d.length;){var g=d[0],h=g.$e.data("sort"),g=(0,a.$table.data("sortFns")[h])(b.columns[g.index],c.columns[g.index]);d.shift()}return 0===g?b.index-c.index:g});a.sort_dir!=c.fn.stupidtable.dir.ASC&&b.reverse();return b},m=function(a,b){var f=c.map(a,function(a,c){return[[a.columns[b.th_index],a.$tr,c]]});b.column=f;return c.map(a,function(a){return a.$tr})},k=function(a,b){var f,d=b.$th,
    e=c.fn.stupidtable.dir;a?f=a:(f=a||d.data("sort-default")||e.ASC,d.data("sort-dir")&&(f=d.data("sort-dir")===e.ASC?e.DESC:e.ASC));return f},h=function(a){var b=0,f=a.$th.index();a.$th.parents("tr").find("th").slice(0,f).each(function(){var a=c(this).attr("colspan")||1;b+=parseInt(a,10)});return b}})(jQuery);

    $(document).ready(function() {
    $(".stupidTable").each(function(idx, ele) {
      $(ele).stupidtable();
    });
    });
  </script>
  """

  @inline_scripts """
  <script>
    /**
    * Report JS
    */

    (function(){
      Prism.hooks.add('complete', function(env) {
        var pre = env.element.parentNode;
        var lines = pre && pre.dataset.line;

        if (!pre || !lines || !/pre/i.test(pre.nodeName)) {
          console.log('nope');
          return;
        }

        var container = pre.parentElement;

        if (!container || !container.classList.contains('code')) {
          return;
        }

        container.style.height = 'auto';
      });
    })();

    jQuery(function(){
      function isVisible(element) {
        return !!(
          element.offsetWidth ||
          element.offsetHeight ||
          element.getClientRects().length
        );
      };

      var pendingElements = [];
      // Convert node list to arrays
      pendingElements.push.apply(
        pendingElements,
        document.querySelectorAll('#smells .code')
      );

      var waypoints = [];

      function updateInView() {
        if (!pendingElements.length) {
          return;
        }

        var visibleElements = pendingElements.filter(isVisible);
        waypoints = visibleElements.map(function(element){
          var $e = $(element),
          elementTop = $e.offset().top;
          return [
            elementTop,
            elementTop + $e.outerHeight(),
            element
          ];
        });
      };

      function inView() {
        var yTop = window.scrollY,
        yBottom = window.scrollY + window.innerHeight;

        return waypoints.filter(function(entry){
          return (entry[0] <= yTop && entry[1] >= yTop) ||
            (entry[0] > yTop && entry[1] < yBottom) ||
            (entry[0] <= yBottom && entry[1] >= yBottom);
        });
      }

      var inViewHandler = function(){
        var entries = inView();
        if (entries.length) {
          entries.forEach(function(entry){
            var containerElement = entry[2];

            if (pendingElements.indexOf(containerElement) === -1) {
              return;
            }

            element = containerElement.querySelector('pre code');

            element.parentElement.style.visibility = 'visible';
            Prism.highlightElement(element);

            pendingElements.splice(
              pendingElements.indexOf(containerElement),
              1
            );
          });
          updateInView();
        }
      };

      function enableInView() {
        window.addEventListener('scroll', inViewHandler);
        window.addEventListener('resize', inViewHandler);
        inViewHandler();
      }

      updateInView();
      enableInView();

      $('summary').on('click', function() {
        setTimeout(function(){
          updateInView();
          inViewHandler();
        },
        1);
      });
    });
  </script>
  """

  def print_issues(issues) do
    issues
    |> Enum.reduce(Map.new(), &Credo.CLI.Output.Formatter.ReportCard.categorize_module/2)
    |> write_html()
  end

  defp write_html(issue_map) do
    File.mkdir("credo")
    {:ok, f} = File.open("credo/index.html", [:binary, :write])

    IO.binwrite(f, [
      "<!doctype html>\n<html>\n<head>\n<title>Credo Report</title>\n",
      @head_links,
      @inline_styles,
      @inline_scripts,
      @table_scripts,
      "</head>\n<body>\n",
      "<div class=\"container\">\n",
      "<div id=\"main-container\">\n"
    ])

    IO.binwrite(f, "<h1>Credo Module Scores</h1>")

    IO.binwrite(f, [
      "<table class=\"stupidTable\">\n",
      "<thead>\n<tr>\n",
      "<th data-sort=\"string\" data-sort-default=\"asc\">File</th>\n",
      "<th data-sort=\"string\" data-sort-default=\"desc\">Grade</th>\n",
      "<th data-sort=\"int\" data-sort-default=\"desc\">Issues</th>\n",
      "<th data-sort=\"int\" data-sort-default=\"desc\">Remediation Time</th>",
      "\n</tr>\n</thead>\n<tbody>\n"
    ])

    issue_map
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.each(fn {k, v} ->
      module_template(f, k, v)
    end)

    IO.binwrite(f, [
      "</tbody>\n</table>\n",
      "</div>\n</div>\n</body>\n</html>"
    ])

    File.close(f)
  end

  defp module_template(io, k, v) do
    {issue_count, raw_score} = Credo.CLI.Output.Formatter.ReportCard.score_issues(k, v)
    mod_grade = Credo.CLI.Output.Formatter.ReportCard.grade(raw_score)
    dir_path = Path.join("credo", Path.dirname(k))
    file_path = Path.join("credo", k <> ".html")
    link_path = k <> ".html"

    IO.binwrite(io, [
      "<tr>\n",
      "<td><a href=\"",
      h(link_path),
      "\">",
      h(k),
      "</a>\n</td>\n",
      "<td>#{mod_grade}</td>",
      "<td>#{issue_count}</td>",
      "<td data-sort-value=#{round(raw_score)}>",
      Credo.CLI.Output.Formatter.ReportCard.format_remediation_time(raw_score),
      "</td>",
      "</tr>\n"
    ])

    File.mkdir_p(dir_path)
    {:ok, f} = File.open(file_path, [:binary, :write])

    IO.binwrite(f, [
      "<!doctype html>\n<html>\n<head>\n<title>",
      h(k),
      "</title>\n",
      @head_links,
      @inline_styles,
      @inline_scripts,
      @table_scripts,
      "</head>\n<body>\n",
      "<div class=\"container\">\n",
      "<div id=\"main-container\">\n",
      "<h1>",
      h(k),
      "</h1>",
      "<ul id=\"smells\">"
    ])

    v
    |> Enum.sort_by(fn i -> i.line_no end)
    |> Enum.each(fn issue -> format_smell(f, issue) end)

    IO.binwrite(f, [
      "</ul>",
      "</div>\n</div>\n</body>\n</html>"
    ])

    File.close(f)
  end

  defp format_smell(f, issue) do
    {target_line, min_line, max_line} = line_indexes(issue)
    IO.binwrite(f, "<li>\n")
    IO.binwrite(f, ["<h2>", h(issue.message), "</h2>"])

    IO.binwrite(f, [
      "<div class=\"code\">\n",
      "<pre class=\"line-numbers language-elixir\" ",
      "data-line=\"#{target_line}\" ",
      "data-start=\"#{min_line}\" ",
      "data-line-offset=\"#{min_line - 1}\"><code>",
      line_content(issue, min_line, max_line),
      "</code>\n</pre>\n</div>\n",
      "<details>\n<summary>Details</summary>\n"
    ])

    IO.binwrite(f, format_explanation(issue))
    IO.binwrite(f, "</details>\n</li>\n")
  end

  defp format_explanation(issue) do
    Enum.map(String.split(issue.check.explanation, "\n\n"), fn sv ->
      case is_source_explanation(sv) do
        false -> "<p>" <> h(sv) <> "</p>\n\n"
        _ -> "<pre><code>" <> h(sv) <> "</pre></code>\n\n"
      end
    end)
  end

  defp is_source_explanation(<<"   ", _::binary>>) do
    true
  end

  defp is_source_explanation(_) do
    false
  end

  defp line_indexes(issue) do
    exact_line = issue.line_no || 1
    first_line = minimum_line(exact_line)
    {:ok, src_lines} = SourceFileLines.get(issue.filename)
    keys = :proplists.get_keys(src_lines)
    {exact_line, first_line, max_line(exact_line, keys)}
  end

  defp line_content(issue, min, max) do
    {:ok, src_lines} = SourceFileLines.get(issue.filename)

    Enum.join(
      Enum.map(Range.new(min, max), fn i ->
        h(:proplists.get_value(i, src_lines))
      end),
      "\n"
    ) <> "\n"
  end

  defp max_line(target_line, keys) do
    case Enum.member?(keys, target_line + 2) do
      false ->
        case Enum.member?(keys, target_line + 1) do
          false -> target_line
          _ -> target_line + 1
        end

      _ ->
        target_line + 2
    end
  end

  def minimum_line(2), do: 1
  def minimum_line(1), do: 1
  def minimum_line(n), do: n - 2

  defp h(binary) do
    html_escape(binary, <<>>)
  end

  defp html_escape(<<>>, str) do
    str
  end

  defp html_escape(<<"'", rest::binary>>, str) do
    html_escape(rest, str <> "&#39;")
  end

  defp html_escape(<<"\"", rest::binary>>, str) do
    html_escape(rest, str <> "&#34;")
  end

  defp html_escape(<<"<", rest::binary>>, str) do
    html_escape(rest, str <> "&#060;")
  end

  defp html_escape(<<">", rest::binary>>, str) do
    html_escape(rest, str <> "&#062;")
  end

  defp html_escape(<<a::size(8), rest::binary>>, str) do
    html_escape(rest, str <> <<a>>)
  end
end
