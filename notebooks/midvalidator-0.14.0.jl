### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 766e600d-200c-4421-9a21-a8fa0aa6a4a7
begin

	using PlutoUI
	using CitableText
	using CitableCorpus
	using CitableObject
	using CitableImage
	using CitablePhysicalText
	using CitableTeiReaders
	using CSV
	using DataFrames
	using EditionBuilders
	using EditorsRepo
	using HTTP
	#using Lycian
	using Markdown
	using Orthography
	using ManuscriptOrthography
	using PolytonicGreek
	using Unicode

end


# ╔═╡ 617ce64a-d7b1-4f66-8bd0-f7a240a929a7
@bind loadem Button("Load/reload data")

# ╔═╡ 8cd70daf-566d-423d-931c-e5021ad2778a
begin
	loadem
	using Pkg
	nbversion = Pkg.TOML.parse(read("Project.toml", String))["version"]
	md"""## Validating notebook: version *$(nbversion)*
	
Problems, suggestions?  Please file an issue in the MID  [`validatormodel` repository](https://github.com/HCMID/validatormodel/issues).

References for HMT editors:  see the [2021 summer experience reference sheet](https://homermultitext.github.io/hmt-se2021/references/)
	
	
	
	
	"""
end

# ╔═╡ 17ebe116-0d7f-4051-a548-1573121a33c9
begin
	loadem
	github = Pkg.TOML.parse(read("MID.toml", String))["github"]
	projectname =	Pkg.TOML.parse(read("MID.toml", String))["projectname"]

	pg = string(
		
		"<blockquote  class='splash'>",
		"<div class=\"center\">",
		"<h2>Project: <em>",
		projectname,
		"</em>",
		"</h2>",
		"</div>",
		"<ul>",
		"<li>On github at:  ",
		"<a href=\"" * github * "\">" * github * "</a>",
		"</li>",
		
		"<li>Repository cloned in: ",
		"<strong>",
		dirname(pwd()),
		"</strong>",
		"</li>",
		"</ul>",

		"</blockquote>"
		)
	
	HTML(pg)
	
end

# ╔═╡ ee2f04c1-42bb-46bb-a381-b12138e550ee
md"> ## Verification: DSE indexing"

# ╔═╡ 834a67df-8c8b-47c6-aa3e-20297576019a
md"""

### Verify *completeness* of indexing


*Check completeness of indexing by following linked thumb to overlay view in the Image Citation Tool*
"""

# ╔═╡ 8fcf792e-71eb-48d9-b0e6-e7e175628ccd
md"*Height of thumbnail image*: $(@bind thumbht Slider(150:500, show_value=true))"


# ╔═╡ 06bfa57d-2bbb-498e-b68e-2892d7186245
md"""
### Verify *accuracy* of indexing

*Check that diplomatic text and indexed image correspond.*


"""

# ╔═╡ ad541819-7d4f-4812-8476-8a307c5c1f87
md"""
*Maximum width of image*: $(@bind w Slider(200:1200, show_value=true))

"""

# ╔═╡ 3dd88640-e31f-4400-9c34-2adc2cd4c532
md"""

> ## Verification:  orthography

"""

# ╔═╡ ea1b6e21-7625-4f8f-a345-8e96449c0757
md"""

---

---


> ### Functions

You don't need to look at the rest of the notebook unless you're curious about how it works.  The following cells define the functions that retreive data from your editing repository, validate it, and format it for visual verification.

"""

# ╔═╡ fd401bd7-38e5-44b5-8131-dbe5eb4fe41b
md"> Formatting"


# ╔═╡ 066b9181-9d41-4013-81b2-bcc37878ab68
# Format HTML for EditingRepository's reporting on cataloging status.
function catalogcheck(editorsrepo::EditingRepository)
	cites = citation_df(editorsrepo)
	if filesmatch(editorsrepo, cites)
		md"✅XML files in repository match catalog entries."
	else
		htmlstrings = []
		
		missingfiles = filesonly(editorsrepo, cites)
		if ! isempty(missingfiles)
			fileitems = map(f -> "<li>" * f * "</li>", missingfiles)
			filelist = "<p>Uncataloged files found on disk: </p><ul>" * join(fileitems,"\n") * "</ul>"
			
			hdr = "<div class='warn'><h1>⚠️ Warning</h1>"
			tail = "</div>"
			badfileshtml = join([hdr, filelist, tail],"\n")
			push!(htmlstrings, badfileshtml)
		end
		
		notondisk = citedonly(editorsrepo, cites)
		if ! isempty(notondisk)
			nofilelist = "<p>Configured files not found on disk: </p><ul>" * join(fileitems , "\n") * "</ul>"
			hdr = "<div class='danger'><h1>🧨🧨 Configuration error 🧨🧨 </h1>" 
			tail = "</div>"
			nofilehtml = join([hdr, nofilelist, tail],"\n")
			push!(htmlstrings,nofilehtml)
		end
		HTML(join(htmlstrings,"\n"))
	end

end

# ╔═╡ 5cba9a9c-74cc-4363-a1ff-026b7b3999ea
#Create list of text labels for popupmenu
function surfacemenu(editorsrepo)
	loadem
	surfurns = EditorsRepo.surfaces(editorsrepo)
	surflist = map(u -> u.urn, surfurns)
	# Add a blank entry so popup menu can come up without a selection
	pushfirst!( surflist, "")
end

# ╔═╡ 1814e3b1-8711-4afd-9987-a41d85fd56d9
# Wrap tokens with invalid orthography in HTML tag
function formatToken(ortho, s)
	
	if isempty(strip(s))
		s
	elseif validstring(ortho, s)
			s
	else
		"""<span class='invalid'>$(s)</span>"""
	end
end

# ╔═╡ 3dd9b96b-8bca-4d5d-98dc-a54e00c75030
css = html"""
<style>
.splash {
	background-color: #f0f7fb;
}
.danger {
     background-color: #fbf0f0;
     border-left: solid 4px #db3434;
     line-height: 18px;
     overflow: hidden;
     padding: 15px 60px;
   font-style: normal;
	  }
.warn {
     background-color: 	#ffeeab;
     border-left: solid 4px  black;
     line-height: 18px;
     overflow: hidden;
     padding: 15px 60px;
   font-style: normal;
  }

  .danger h1 {
	color: red;
	}

 .invalidtoken {
	text-decoration-line: underline;
  	text-decoration-style: wavy;
  	text-decoration-color: red;
}
 .invalid {
	color: red;
	border: solid;
}
 .center {
text-align: center;
}
.highlight {
  background: yellow;  
}
.urn {
	color: silver;
}
  .note { -moz-border-radius: 6px;
     -webkit-border-radius: 6px;
     background-color: #eee;
     background-image: url(../Images/icons/Pencil-48.png);
     background-position: 9px 0px;
     background-repeat: no-repeat;
     border: solid 1px black;
     border-radius: 6px;
     line-height: 18px;
     overflow: hidden;
     padding: 15px 60px;
    font-style: italic;
 }


.instructions {
     background-color: #f0f7fb;
     border-left: solid 4px  #3498db;
     line-height: 18px;
     overflow: hidden;
     padding: 15px 60px;
   font-style: normal;
  }



</style>
"""

# ╔═╡ ec0f3c61-cf3b-4e4c-8419-176626a0888c
md"> Repository and image services"

# ╔═╡ 43734e4f-2efc-4f12-81ac-bce7bf7ada0a
# Create EditingRepository for this notebook's repository
# Since the notebook is in the `notebooks` subdirectory of the repository,
# we can just use the parent directory (dirname() in julia) for the
# root directory.
function editorsrepo() 
    repository(dirname(pwd()))
end

# ╔═╡ 35255eb9-1f54-4f9d-8c58-2d450e09dff9
begin
	loadem
	editorsrepo() |> catalogcheck
end

# ╔═╡ 8d407e7a-1201-4dd3-bddd-368362037205
md"""###  Choose a surface to verify

$(@bind surface Select(surfacemenu(editorsrepo())))
"""

# ╔═╡ 3cb683e2-5350-4262-b693-0cddee340254
# Compose HTML to display compliance with configured orthography
function orthography()
	if isempty(surface)
		md""
	else
	
		textconfig = citation_df(editorsrepo())
		catalog = textcatalog_df(editorsrepo())
		sdse = EditorsRepo.surfaceDse(editorsrepo(), Cite2Urn(surface))
		
		htmlrows = []
		for row in eachrow(sdse)
			tidy = EditorsRepo.baseurn(row.passage)
			ortho = orthographyforurn(textconfig, tidy)
			title = worktitle(catalog, row.passage)
			
			#chunks = normednodetext(editorsrepo(), row.passage) |> split
			chunks = graphemes(normednodetext(editorsrepo(), row.passage)) |> collect
			html = []
			for chunk in chunks
				push!(html, formatToken(ortho, chunk))
			end
			
			psg = passagecomponent(tidy)
			htmlrow =  string("<p><i>$title</>, <b>$psg</b> ", join(html), "</p>")
			push!(htmlrows,htmlrow)
		end
		HTML(join(htmlrows,"\n"))
	end
end

# ╔═╡ 3b04a423-6d0e-4221-8540-ad457d0bb65e
orthography()

# ╔═╡ 080b744e-8f14-406d-bdd2-fbcd3c1ec753
# Base URL for an ImageCitationTool
function ict()
	"http://www.homermultitext.org/ict2/?"
end

# ╔═╡ 806b3733-6c06-4956-8b86-aa096f060ac6
# API to work with an IIIF image service
function iiifsvc()
	IIIFservice("http://www.homermultitext.org/iipsrv",
	"/project/homer/pyramidal/deepzoom")
end

# ╔═╡ 71d7a180-5742-415c-9013-d3d1c0ca920c

# Compose markdown for thumbnail images linked to ICT with overlay of all
# DSE regions.
function completenessView(urn, repo)
     
	# Group images with ROI into a dictionary keyed by image
	# WITHOUT RoI.
	grouped = Dict()
	for row in eachrow(surfaceDse(repo, urn))
		trimmed = CitableObject.dropsubref(row.image)
		if haskey(grouped, trimmed)
			push!(grouped[trimmed], row.image)
		else
			grouped[trimmed] = [row.image]
		end
	end

	mdstrings = []
	for k in keys(grouped)
		thumb = markdownImage(k, iiifsvc(), thumbht)
		params = map(img -> "urn=" * img.urn * "&", grouped[k]) 
		lnk = ict() * join(params,"") 
		push!(mdstrings, "[$(thumb)]($(lnk))")
		
	end
	join(mdstrings, " ")

end

# ╔═╡ 9e6f8bf9-4aa7-4253-ba3f-695b13ca6def
# Display link for completeness view
begin
	if isempty(surface)
		md""
	else
		Markdown.parse(completenessView(Cite2Urn(surface), editorsrepo()))
	end
end

# ╔═╡ 59fbd3de-ea0e-4b96-800c-d5d8a7272922
# Compose markdown for one row of display interleaving citable
# text passage and indexed image.
function accuracyView(row::DataFrameRow)
	textcatalog = textcatalog_df(editorsrepo())
    title 	= worktitle(textcatalog, row.passage)
	citation = string("*", title, "*, **" * passagecomponent(row.passage)  * "** ")

	
	txt = diplnodetext(editorsrepo(), row.passage, )
	caption = passagecomponent(row.passage)
	
	img = linkedMarkdownImage(ict(), row.image, iiifsvc(); ht=w, caption=caption)
	
	#urn
	record = """$(citation) $(txt)

$(img)

---
"""
	record
end

# ╔═╡ 73839e47-8199-4755-8d55-362185907c45
# Display for visual validation of DSE indexing
begin

	if surface == ""
		md""
	else
		surfDse = surfaceDse(editorsrepo(), Cite2Urn(surface) )
		cellout = []
		
		try
			for r in eachrow(surfDse)
				push!(cellout, accuracyView(r))
			end

		catch e
			html"<p class='danger'>Problem with XML edition: see message below</p>"
		end
		Markdown.parse(join(cellout,"\n"))				
		
	end

end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
CitableCorpus = "cf5ac11a-93ef-4a1a-97a3-f6af101603b5"
CitableImage = "17ccb2e5-db19-44b3-b354-4fd16d92c74e"
CitableObject = "e2b2f5ea-1cd8-4ce8-9b2b-05dad64c2a57"
CitablePhysicalText = "e38a874e-a7c2-4ff3-8dea-81ae2e5c9b07"
CitableTeiReaders = "b4325aa9-906c-402e-9c3f-19ab8a88308e"
CitableText = "41e66566-473b-49d4-85b7-da83b66615d8"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
EditionBuilders = "2fb66cca-c1f8-4a32-85dd-1a01a9e8cd8f"
EditorsRepo = "3fa2051c-bcb6-4d65-8a68-41ff86d56437"
HTTP = "cd3eb016-35fb-5094-929b-558a96fad6f3"
ManuscriptOrthography = "c7d01213-112e-44c9-bed3-ac95fd3728c7"
Markdown = "d6f4376e-aef5-505a-96c1-9c027394607a"
Orthography = "0b4c9448-09b0-4e78-95ea-3eb3328be36d"
Pkg = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
PolytonicGreek = "72b824a7-2b4a-40fa-944c-ac4f345dc63a"
Unicode = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[compat]
CSV = "~0.8.5"
CitableCorpus = "~0.2.1"
CitableImage = "~0.1.8"
CitableObject = "~0.6.0"
CitablePhysicalText = "~0.2.7"
CitableTeiReaders = "~0.6.4"
CitableText = "~0.9.0"
DataFrames = "~1.2.0"
EditionBuilders = "~0.4.4"
EditorsRepo = "~0.12.0"
HTTP = "~0.9.12"
ManuscriptOrthography = "~0.1.2"
Orthography = "~0.8.0"
PlutoUI = "~0.7.9"
PolytonicGreek = "~0.12.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

[[ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[AtticGreek]]
deps = ["DocStringExtensions", "Documenter", "Orthography", "PolytonicGreek", "Test", "Unicode"]
git-tree-sha1 = "33d9ae46379002ec79e0925d88e679cc5da94c72"
uuid = "330c8319-f7ed-461a-8c52-cee5da4c0892"
version = "0.6.0"

[[Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[BenchmarkTools]]
deps = ["JSON", "Logging", "Printf", "Statistics", "UUIDs"]
git-tree-sha1 = "9e62e66db34540a0c919d72172cc2f642ac71260"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "0.5.0"

[[CSV]]
deps = ["Dates", "Mmap", "Parsers", "PooledArrays", "SentinelArrays", "Tables", "Unicode"]
git-tree-sha1 = "b83aa3f513be680454437a0eee21001607e5d983"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.8.5"

[[CitableBase]]
deps = ["DocStringExtensions", "Documenter", "Test"]
git-tree-sha1 = "e1edbddb151b18f8290b8f19e4310c369b01c049"
uuid = "d6f014bd-995c-41bd-9893-703339864534"
version = "1.2.2"

[[CitableCorpus]]
deps = ["CSV", "CitableText", "DataFrames", "DocStringExtensions", "Documenter", "HTTP", "Test"]
git-tree-sha1 = "ce07aadee5fe89c3e72667a72ea804502b7e2dcf"
uuid = "cf5ac11a-93ef-4a1a-97a3-f6af101603b5"
version = "0.2.1"

[[CitableImage]]
deps = ["CitableBase", "CitableObject", "DocStringExtensions", "Documenter", "Test"]
git-tree-sha1 = "641e12da892bea327db7f51c4f402a8af8306d22"
uuid = "17ccb2e5-db19-44b3-b354-4fd16d92c74e"
version = "0.1.8"

[[CitableObject]]
deps = ["CitableBase", "DocStringExtensions", "Documenter", "Test"]
git-tree-sha1 = "26433318def871240c90de244a364f056ace7041"
uuid = "e2b2f5ea-1cd8-4ce8-9b2b-05dad64c2a57"
version = "0.6.0"

[[CitablePhysicalText]]
deps = ["CitableObject", "CitableText", "DataFrames", "DocStringExtensions", "Documenter", "Test"]
git-tree-sha1 = "211a8b35fa2265b80da50939514b5342a991ce56"
uuid = "e38a874e-a7c2-4ff3-8dea-81ae2e5c9b07"
version = "0.2.7"

[[CitableTeiReaders]]
deps = ["CitableCorpus", "CitableText", "DocStringExtensions", "Documenter", "EzXML", "Test"]
git-tree-sha1 = "82e0d3a70d8a689b6f8b0f764591d6bbdc0f6d16"
uuid = "b4325aa9-906c-402e-9c3f-19ab8a88308e"
version = "0.6.4"

[[CitableText]]
deps = ["BenchmarkTools", "CitableBase", "DocStringExtensions", "Documenter", "Test"]
git-tree-sha1 = "3d95c0ceea520fae5248a6842026b99d6ca23356"
uuid = "41e66566-473b-49d4-85b7-da83b66615d8"
version = "0.9.0"

[[CiteEXchange]]
deps = ["CitableObject", "DocStringExtensions", "Documenter", "Test"]
git-tree-sha1 = "ad1d80adea90ef286b9f1cfd7de62e71d2c48b4c"
uuid = "e2e9ead3-1b6c-4e96-b95f-43e6ab899178"
version = "0.3.0"

[[Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "dc7dedc2c2aa9faf59a55c622760a25cbefbe941"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.31.0"

[[Crayons]]
git-tree-sha1 = "3f71217b538d7aaee0b69ab47d9b7724ca8afa0d"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.0.4"

[[DataAPI]]
git-tree-sha1 = "ee400abb2298bd13bfc3df1c412ed228061a2385"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.7.0"

[[DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Reexport", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "1dadfca11c0e08e03ab15b63aaeda55266754bad"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.2.0"

[[DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "4437b64df1e0adccc3e5d1adbc3ac741095e4677"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.9"

[[DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "a32185f5428d3986f47c2ab78b1f216d5e6cc96f"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.5"

[[Documenter]]
deps = ["Base64", "Dates", "DocStringExtensions", "IOCapture", "InteractiveUtils", "JSON", "LibGit2", "Logging", "Markdown", "REPL", "Test", "Unicode"]
git-tree-sha1 = "3ebb967819b284dc1e3c0422229b58a40a255649"
uuid = "e30172f5-a6a5-5a46-863b-614d45cd2de4"
version = "0.26.3"

[[Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[EditionBuilders]]
deps = ["CitableCorpus", "CitableText", "DocStringExtensions", "Documenter", "EzXML", "Test"]
git-tree-sha1 = "5fdf695f515c1146a2604f39e1b7a4f93d28b601"
uuid = "2fb66cca-c1f8-4a32-85dd-1a01a9e8cd8f"
version = "0.4.4"

[[EditorsRepo]]
deps = ["AtticGreek", "CSV", "CitableBase", "CitableCorpus", "CitableObject", "CitablePhysicalText", "CitableTeiReaders", "CitableText", "CiteEXchange", "DataFrames", "DocStringExtensions", "Documenter", "EditionBuilders", "Lycian", "ManuscriptOrthography", "Orthography", "PolytonicGreek", "Test"]
git-tree-sha1 = "923bbd8751ab80a034eb5fce4f61b9d71e02064d"
uuid = "3fa2051c-bcb6-4d65-8a68-41ff86d56437"
version = "0.12.0"

[[EzXML]]
deps = ["Printf", "XML2_jll"]
git-tree-sha1 = "0fa3b52a04a4e210aeb1626def9c90df3ae65268"
uuid = "8f5d6c58-4d21-5cfd-889c-e3ad7ee6a615"
version = "1.1.0"

[[Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[HTTP]]
deps = ["Base64", "Dates", "IniFile", "Logging", "MbedTLS", "NetworkOptions", "Sockets", "URIs"]
git-tree-sha1 = "c6a1fff2fd4b1da29d3dccaffb1e1001244d844e"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "0.9.12"

[[IOCapture]]
deps = ["Logging"]
git-tree-sha1 = "377252859f740c217b936cebcd918a44f9b53b59"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.1.1"

[[IniFile]]
deps = ["Test"]
git-tree-sha1 = "098e4d2c533924c921f9f9847274f2ad89e018b8"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.0"

[[InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[InvertedIndices]]
deps = ["Test"]
git-tree-sha1 = "15732c475062348b0165684ffe28e85ea8396afc"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.0.0"

[[IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "642a199af8b68253517b80bd3bfd17eb4e84df6e"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.3.0"

[[JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "81690084b6198a2e1da36fcfda16eeca9f9f24e4"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.1"

[[LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "42b62845d70a619f063a7da093d995ec8e15e778"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+1"

[[LinearAlgebra]]
deps = ["Libdl"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[Lycian]]
deps = ["DocStringExtensions", "Documenter", "Orthography", "Test"]
git-tree-sha1 = "0afb5162d76290e586e586bdd2fa478a42fad3de"
uuid = "7c215dd3-d1b4-4517-b6c6-0123f1059a20"
version = "0.2.0"

[[ManuscriptOrthography]]
deps = ["DocStringExtensions", "Documenter", "Orthography", "PolytonicGreek", "Test", "Unicode"]
git-tree-sha1 = "37d0d0667a6a1dbe5095f74da05b0a240c5502a6"
uuid = "c7d01213-112e-44c9-bed3-ac95fd3728c7"
version = "0.1.2"

[[Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "Random", "Sockets"]
git-tree-sha1 = "1c38e51c3d08ef2278062ebceade0e46cefc96fe"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.0.3"

[[MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "4ea90bd5d3985ae1f9a908bd4500ae88921c5ce7"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.0"

[[Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[Orthography]]
deps = ["DocStringExtensions", "Documenter", "Test", "Unicode"]
git-tree-sha1 = "5593d0e9ef2779815073c641f63eca7ea0e2e046"
uuid = "0b4c9448-09b0-4e78-95ea-3eb3328be36d"
version = "0.8.0"

[[Parsers]]
deps = ["Dates"]
git-tree-sha1 = "c8abc88faa3f7a3950832ac5d6e690881590d6dc"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "1.1.0"

[[Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[PlutoUI]]
deps = ["Base64", "Dates", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "Suppressor"]
git-tree-sha1 = "44e225d5837e2a2345e69a1d1e01ac2443ff9fcb"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.9"

[[PolytonicGreek]]
deps = ["DocStringExtensions", "Documenter", "Orthography", "Test", "Unicode"]
git-tree-sha1 = "db92251590915f8488ebb3ffa2f2b4376e0146b5"
uuid = "72b824a7-2b4a-40fa-944c-ac4f345dc63a"
version = "0.12.1"

[[PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "cde4ce9d6f33219465b55162811d8de8139c0414"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.2.1"

[[Preferences]]
deps = ["TOML"]
git-tree-sha1 = "00cfd92944ca9c760982747e9a1d0d5d86ab1e5a"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.2.2"

[[PrettyTables]]
deps = ["Crayons", "Formatting", "Markdown", "Reexport", "Tables"]
git-tree-sha1 = "0d1245a357cc61c8cd61934c07447aa569ff22e6"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "1.1.0"

[[Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[Random]]
deps = ["Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[Reexport]]
git-tree-sha1 = "5f6c21241f0f655da3952fd60aa18477cf96c220"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.1.0"

[[SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "ffae887d0f0222a19c406a11c3831776d1383e3d"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.3.3"

[[Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[Suppressor]]
git-tree-sha1 = "a819d77f31f83e5792a76081eee1ea6342ab8787"
uuid = "fd094767-a336-5f1f-9728-57cf17d0bbfb"
version = "0.2.0"

[[TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "TableTraits", "Test"]
git-tree-sha1 = "8ed4a3ea724dac32670b062be3ef1c1de6773ae8"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.4.4"

[[Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[URIs]]
git-tree-sha1 = "97bbe755a53fe859669cd907f2d96aee8d2c1355"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.3.0"

[[UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "1acf5bdf07aa0907e0a37d3718bb88d4b687b74a"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.9.12+0"

[[Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
"""

# ╔═╡ Cell order:
# ╟─766e600d-200c-4421-9a21-a8fa0aa6a4a7
# ╟─8cd70daf-566d-423d-931c-e5021ad2778a
# ╟─17ebe116-0d7f-4051-a548-1573121a33c9
# ╟─35255eb9-1f54-4f9d-8c58-2d450e09dff9
# ╟─617ce64a-d7b1-4f66-8bd0-f7a240a929a7
# ╟─8d407e7a-1201-4dd3-bddd-368362037205
# ╟─ee2f04c1-42bb-46bb-a381-b12138e550ee
# ╟─834a67df-8c8b-47c6-aa3e-20297576019a
# ╟─8fcf792e-71eb-48d9-b0e6-e7e175628ccd
# ╟─9e6f8bf9-4aa7-4253-ba3f-695b13ca6def
# ╟─06bfa57d-2bbb-498e-b68e-2892d7186245
# ╟─ad541819-7d4f-4812-8476-8a307c5c1f87
# ╟─73839e47-8199-4755-8d55-362185907c45
# ╟─3dd88640-e31f-4400-9c34-2adc2cd4c532
# ╟─3b04a423-6d0e-4221-8540-ad457d0bb65e
# ╟─ea1b6e21-7625-4f8f-a345-8e96449c0757
# ╟─fd401bd7-38e5-44b5-8131-dbe5eb4fe41b
# ╟─066b9181-9d41-4013-81b2-bcc37878ab68
# ╟─5cba9a9c-74cc-4363-a1ff-026b7b3999ea
# ╟─71d7a180-5742-415c-9013-d3d1c0ca920c
# ╟─59fbd3de-ea0e-4b96-800c-d5d8a7272922
# ╟─3cb683e2-5350-4262-b693-0cddee340254
# ╟─1814e3b1-8711-4afd-9987-a41d85fd56d9
# ╟─3dd9b96b-8bca-4d5d-98dc-a54e00c75030
# ╟─ec0f3c61-cf3b-4e4c-8419-176626a0888c
# ╟─43734e4f-2efc-4f12-81ac-bce7bf7ada0a
# ╟─080b744e-8f14-406d-bdd2-fbcd3c1ec753
# ╟─806b3733-6c06-4956-8b86-aa096f060ac6
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
