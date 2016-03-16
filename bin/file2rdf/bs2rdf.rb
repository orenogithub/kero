require 'zlib'
require 'rdf'
require "rdf/vocab"
require 'rdf/turtle'
include RDF

input_file = ARGV[0] || "../samples/bs_data_9606_LC2ad_reduced.tab.gz"

#########################################################
#  define PREFIX
#########################################################
rdf     = RDF::Vocabulary.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#")
rdfs    = RDF::Vocabulary.new("http://www.w3.org/2000/01/rdf-schema#")
dcterms = RDF::Vocabulary.new("http://purl.org/dc/terms/")
faldo   = RDF::Vocabulary.new("http://biohackathon.org/resource/faldo#")
obo     = RDF::Vocabulary.new("http://purl.obolibrary.org/obo/")
kero    = RDF::Vocabulary.new("http://kero.hgc.jp/ontology/kero.owl#")
kerobs  = RDF::Vocabulary.new("http://kero.hgc.jp/data/kero/9/BSseq/")
dataset = RDF::Vocabulary.new("http://kero.hgc.jp/dataset/kero/9/BSseq/")
chr     = RDF::Vocabulary.new("http://kero.hgc.jp/resource/homo_sapiens/hg38/")

puts "@prefix rdf: <#{RDF::URI(rdf)}> ."
puts "@prefix rdfs: <#{RDF::URI(rdfs)}> ."
puts "@prefix dct: <#{RDF::URI(dcterms)}> ."
puts "@prefix faldo: <#{RDF::URI(faldo)}> ."
puts "@prefix obo: <#{RDF::URI(obo)}> ."
puts "@prefix kero: <#{RDF::URI(kero)}> ."
puts "@prefix kerobs: <#{RDF::URI(kerobs)}> ."
puts "@prefix chr: <#{RDF::URI(chr)}> ."
puts "@prefix dataset: <#{RDF::URI(dataset)}> ."

dataset_name = input_file.split("/")[-1]
sample    = dataset_name.split("_")[3]
dataset_name = RDF::URI("http://kero.hgc.jp/dataset/kero/9/BSseq/#{sample}")

graph = RDF::Graph.new

graph << [dataset_name, RDF.type, kero.MethylSeqDataset]
graph << [dataset_name, rdfs.label, "kero BS-seq dataset of #{sample}"]

graph = graph.dump(:ttl, prefixes:{
  rdf:     "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
  rdfs:    "http://www.w3.org/2000/01/rdf-schema#",
  kero:    "http://kero.hgc.jp/ontology/kero.owl#",
  dataset: "http://kero.hgc.jp/dataset/kero/9/BSseq/"
})
puts graph.gsub(/^@.+\n/, "")

Zlib::GzipReader.open(input_file).each do |line|
  local_id, bin, chr, pos, cg, ca, sum = line.chomp.split("\t")
  chr = chr.delete("chr")
  
  g      = RDF::Graph.new
  
  id     = RDF::URI("http://kero.hgc.jp/data/kero/9/BSseq/#{sample}_#{local_id}")  
  region = RDF::URI("http://kero.hgc.jp/resource/homo_sapiens/hg38/#{chr}_#{pos}-#{pos}")
  p_node = RDF::URI("http://kero.hgc.jp/resource/homo_sapiens/hg38/#{chr}_#{pos}")
  chrom  = RDF::URI("http://kero.hgc.jp/resource/homo_sapiens/hg38/#{chr}")
  
  g << [dataset_name, kero.hasMethylationSite, id]

  g << [id, RDF.type, obo.SO_0000306] #A nucleotide modified by methylation.
  g << [id, rdfs.label, "Methylation site on chromosome #{chr}:#{pos}"]
  g << [id, dcterms.identifier, "#{sample}_#{local_id}"]
  g << [id, kero.cgNum, cg.to_i]
  g << [id, kero.caNum, ca.to_i]
  g << [id, kero.bin, bin.to_i]
  
  # FALDO
  g << [id, faldo.location, region]
  g << [region, RDF.type, faldo.Region]
  g << [region, rdfs.label, "chromosome #{chr}:#{pos}-#{pos}"]
  g << [region, faldo.begin, p_node]
  g << [region, faldo.end, p_node]
  g << [region, faldo.reference, chrom]
  
  g << [p_node, RDF.type, faldo.ExactPosition]
  g << [p_node, RDF.type, faldo.StrandedPosition]
  g << [p_node, rdfs.label, "chromosome #{chr}:#{pos}"]
  g << [p_node, faldo.position, pos.to_i]
  g << [p_node, faldo.reference, chrom]
  
  g = g.dump(:ttl, prefixes:{
    rdf:      "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    rdfs:     "http://www.w3.org/2000/01/rdf-schema#",
    dcterms:  "http://purl.org/dc/terms/",
    faldo:    "http://biohackathon.org/resource/faldo#",
    obo:      "http://purl.obolibrary.org/obo/",
    resource: "http://kero.hgc.jp/resource/homo_sapiens/hg38/",
    kero:     "http://kero.hgc.jp/ontology/kero.owl#",
    kerobs:   "http://kero.hgc.jp/data/kero/9/BSseq/",
    dataset:  "http://kero.hgc.jp/dataset/kero/9/BSseq/"
  })
  puts g.gsub(/^@.+\n/, "")
  g.clear
end