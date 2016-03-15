require 'zlib'
require 'rdf'
require "rdf/vocab"
require 'rdf/turtle'
include RDF

input_file = ARGV[0] || "../samples/bs_data_9606_LC2ad_reduced.tab.gz"

#########################################################
#  define PREFIX
#########################################################
rdf    = RDF::Vocabulary.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#")
rdfs   = RDF::Vocabulary.new("http://www.w3.org/2000/01/rdf-schema#")
dct    = RDF::Vocabulary.new("http://purl.org/dc/terms/")
faldo  = RDF::Vocabulary.new("http://biohackathon.org/resource/faldo#")
so     = RDF::Vocabulary.new("http://purl.obolibrary.org/obo/")
kero   = RDF::Vocabulary.new("http://kero.hgc.jp/ontology/kero.owl#")
chr    = RDF::Vocabulary.new("http://kero.hgc.jp/rdf/resource/kero/9/homo_sapiens/hg38/")
bs     = RDF::Vocabulary.new("http://kero.hgc.jp/rdf/BSseq/")
file   = RDF::Vocabulary.new("ftp://ftp.hgc.jp/pub/hgc/db/dbtss/dbtss_ver9/hg38/BSseq/hg38_liftover/")

puts "@prefix rdf: <#{RDF::URI(rdf)}> ."
puts "@prefix rdfs: <#{RDF::URI(rdfs)}> ."
puts "@prefix dct: <#{RDF::URI(dct)}> ."
puts "@prefix faldo: <#{RDF::URI(faldo)}> ."
puts "@prefix so: <#{RDF::URI(so)}> ."
puts "@prefix kero: <#{RDF::URI(kero)}> ."
puts "@prefix chr: <#{RDF::URI(chr)}> ."
puts "@prefix bs: <#{RDF::URI(bs)}> ."
puts "@prefix file: <#{RDF::URI(file)}> ."

file_name = input_file.split("/")[-1]
sample    = file_name.split("_")[3]
file_name = RDF::URI("ftp://ftp.hgc.jp/pub/hgc/db/dbtss/dbtss_ver9/hg38/BSseq/hg38_liftover/#{file_name}")

graph = RDF::Graph.new

graph << [file_name, RDF.type, kero.MethylSeqFile]
graph << [file_name, rdfs.label, "BS-seq of #{sample}"]

graph = graph.dump(:ttl, prefixes:{
  rdf:    "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
  rdfs:   "http://www.w3.org/2000/01/rdf-schema#",
  kero:   "http://kero.hgc.jp/ontology/kero.owl#",
  file:   "ftp://ftp.hgc.jp/pub/hgc/db/dbtss/dbtss_ver9/hg38/BSseq/hg38_liftover/"
})
puts graph.gsub(/^@.+\n/, "")

Zlib::GzipReader.open(input_file).each do |line|
  local_id, bin, chr, pos, cg, ca, sum = line.chomp.split("\t")
  chr = chr.delete("chr")
  
  g      = RDF::Graph.new
  
  id     = RDF::URI("http://kero.hgc.jp/rdf/BSseq/#{sample}_#{local_id}")  
  region = RDF::URI("http://kero.hgc.jp/rdf/resource/kero/9/homo_sapiens/hg38/#{chr}:#{pos}-#{pos}")
  p_node = RDF::URI("http://kero.hgc.jp/rdf/resource/kero/9/homo_sapiens/hg38/#{chr}:#{pos}")
  chrom  = RDF::URI("http://kero.hgc.jp/rdf/resource/kero/9/homo_sapiens/hg38/#{chr}")
  
  g << [file_name, kero.hasMethylationSite, id]

  g << [id, RDF.type, so.SO_0000306] #A nucleotide modified by methylation.
  g << [id, rdfs.label, "Methylation site on chr#{chr}:#{pos}"]
  g << [id, dct.identifier, "#{sample}_#{local_id}"]
  g << [id, kero.cgNum, cg.to_i]
  g << [id, kero.caNum, ca.to_i]
  g << [id, kero.bin, bin.to_i]
  
  # FALDO
  g << [id, faldo.location, region]
  g << [region, RDF.type, faldo.Region]
  g << [region, rdfs.label, "chr#{chr}:#{pos}-#{pos}"]
  g << [region, faldo.begin, p_node]
  g << [region, faldo.end, p_node]
  g << [region, faldo.reference, chrom]
  
  g << [p_node, RDF.type, faldo.ExactPosition]
  g << [p_node, RDF.type, faldo.StrandedPosition]
  g << [p_node, rdfs.label, "chr#{chr}:#{pos}"]
  g << [p_node, faldo.position, pos.to_i]
  g << [p_node, faldo.reference, chrom]
  
  g = g.dump(:ttl, prefixes:{
    rdf:    "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    rdfs:   "http://www.w3.org/2000/01/rdf-schema#",
    dct:    "http://purl.org/dc/terms/",
    faldo:  "http://biohackathon.org/resource/faldo#",
    so:     "http://purl.obolibrary.org/obo/",
    #chr:    "http://kero.hgc.jp/rdf/resource/kero/9/homo_sapiens/hg38/",
    kero:   "http://kero.hgc.jp/ontology/kero.owl#",
    bs:     "http://kero.hgc.jp/rdf/BSseq/",
    file:   "ftp://ftp.hgc.jp/pub/hgc/db/dbtss/dbtss_ver9/hg38/BSseq/hg38_liftover/"
  })
  puts g.gsub(/^@.+\n/, "")
  g.clear
end