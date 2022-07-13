# Run this dashboard from the root of the
# github repository:
using Pkg
Pkg.activate(joinpath(pwd(), "dashboard"))
Pkg.instantiate()

DASHBOARD_VERSION = "0.17.0"

using Dash
using CitableBase
using CitableText
using CitableCorpus
using CitableObject
using CitableImage
using CitablePhysicalText
using CitableTeiReaders
using EditionBuilders
using Orthography
using EditorsRepo

THUMBHEIGHT = 200
TEXTHEIGHT = 600

r = repository(pwd())

assetfolder = joinpath(pwd(), "dashboard", "assets")
app = dash(assets_folder = assetfolder, include_assets_files=true)

app.layout = html_div() do
    dcc_markdown() do 
        """*Dashboard version*: **$(DASHBOARD_VERSION)**. 
        """
    end,
    html_h1("MID validating dashboard"),
    
    html_button("Load/update data", id="load_button"),
    html_div(children="No data loaded", id="datastate"),
   
    html_h2("Choose a surface to validate"),
    html_div(style = Dict("width" => "600px")) do
        dcc_dropdown(id = "surfacepicker")
    end,

    html_div(id="dsecompleteness"),
    html_div(id="dseaccuracy"),
    html_div(id="orthography")
end

"Update surfaces menu and set user message about number of times data loaded."
function updaterepodata(n_clicks)
    msg = if isnothing(n_clicks)
        dcc_markdown("*No data loaded yet*")
    elseif n_clicks ==  1
        dcc_markdown("Data loaded.")
    else
        dcc_markdown("""Data loaded **$(n_clicks)** times.""")
    end

    menupairs = [(label="", value="")]
    for s in surfaces(r, strict = false)
		push!(menupairs, (label=string(s), value=string(s)))
	end
    (msg, menupairs )
end


# Update surfaces menu and user message when "Load/update data" button
# is clicked:
callback!(
    updaterepodata,
    app,
    Output("datastate", "children"),
    Output("surfacepicker", "options"),
    Input("load_button", "n_clicks"),
    prevent_initial_call=true
)

# Update validation/verification sections of page when surface is selected:
callback!(
    app,
    Output("dsecompleteness", "children"),
    Output("dseaccuracy", "children"),
    Output("orthography", "children"),
    Input("surfacepicker", "value")
) do newsurface
    if isnothing(newsurface) || isempty(newsurface)
        (dcc_markdown(""), dcc_markdown(""), dcc_markdown(""))
    else
        surfurn = Cite2Urn(newsurface)
        completenesshdr = "> ## 1. Verification of DSE indexing\n\n### 1.A. Verify completeness of indexing\n*Use the linked thumbnail image to see this surface in the Image Citation Tool.*\n\n"
        completenessimg = indexingcompleteness_html(r, surfurn, height=THUMBHEIGHT, strict = false)
        
        completeness = dcc_markdown(completenesshdr * completenessimg)
        
        accuracyhdr = "### 1.B. Verify accuracy of indexing\n*Check that the diplomatic reading and the indexed image correspond.*\n\n"
        accuracypassages = indexingaccuracy_html(r, surfurn, height=TEXTHEIGHT, strict = false)
        accuracy = dcc_markdown(accuracyhdr * accuracypassages)
        
        orthohdr = "> ## 2. Verification: orthography\n\nHighlighted tokens contain invalid characters.\n\n"
        orthopsgs = orthographicvalidity_html(r, surfurn, strict = false)
        orthography = dcc_markdown(orthohdr * orthopsgs,dangerously_allow_html=true)

        (completeness, accuracy, orthography)
    end
end

run_server(app, "0.0.0.0", 8051, debug=true)