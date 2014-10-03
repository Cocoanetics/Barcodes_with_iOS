#!/usr/bin/env ruby

require 'json'
require "openssl"

# pass details
# --- note: customize to your needs!
passTypeIdentifier = "pass.com.drobnik.vipmovie"
teamIdentifier = "Z7L2YCUH45"
organizationName = "Cocoanetics Cinema"
logoText = "Cocoanetics"
description = "VIP Movie Night Sofa Seat"
eventDate = Time.new(2014, 8, 13, 16, 0, 0, "+02:00")
seat = "1A"
event_latitude = 14.5877
event_longitude = 48.0528
# --- note: a few less frequently changed values are further down

# use current timestamp as serial number
serialNumber = Time.now.to_i.to_s
passFileName = serialNumber + ".pkpass"

# date will be represented as string in JSON
eventDateString = eventDate.utc.strftime("%Y-%m-%dT%H:%M:%SZ")

# check/load WWDR root certificate
begin
  rootCertFile = File.read('AppleWWDRCA.cer')
  rootCert = OpenSSL::X509::Certificate.new rootCertFile
rescue => err
  puts "Cannot load root certificate: #{err}"
  exit 1
end

# check/load signing certificate
begin
  certificate = OpenSSL::X509::Certificate.new File.read('passtypecert.pem')
rescue => err
  puts "Cannot load signing certificate: #{err}"
  exit 1
end

# check/load private signing key
begin  
  privateKeyFile = File.read('passtypecertkey.pem')
  privateKey = OpenSSL::PKey::RSA.new privateKeyFile, '12345'
rescue => err
  puts "Cannot load private signing key: #{err}"
  exit 1
end

# assemble a "signed" barcode message 
barcodeMessage = "TICKET:#{eventDateString},#{seat},#{serialNumber}"
salt = "EXTRA SECRET SAUCE"
barcodeMessageSignature = Digest::SHA1.hexdigest barcodeMessage + salt
barcodeMessage = barcodeMessage + "|#{barcodeMessageSignature}"

# create the barcode
barcode = { 
  "format" => "PKBarcodeFormatQR",
  "messageEncoding" => "iso-8859-1"
}
barcode["message"] = barcodeMessage

# header fields
headerFields = [{
  "key" => "seat",
  "label" => "Seat",
  "value" => seat
}]
                  
# primary fields                  
primaryFields = [{
  "key" => "name",
  "value" => "VIP Movie Night"
}]                  

# secondary fields                  
secondaryFields = [{
  "key" => "location",
  "label" => "Location",
  "value" => "Oliver's Home Movie Theater"
}]                  

# auxiliary fields
auxiliaryFields = [{
  "key" => "date",
  "label" => "Event Date",
  "dateStyle" => "PKDateStyleMedium",      
  "timeStyle" => "PKDateStyleShort",
  "value" => eventDateString 
}]
 
# fields on back of pass
backFields = [
  {
  "key" => "phone",
  "label" => "For more info",
  "value" => "800-1234567890"
  },
  {
  "key" => "terms",
  "label" => "TERMS AND CONDITIONS",
  "value" => "Free popcorn and drink at entrance. Please arrive sufficiently early to pick your seat and allow show to start on time."
  }
] 

# assemble the pass in a hash
pass = {
  "formatVersion" => 1
}

# add barcode
pass["barcode"] = barcode

# add pass meta data
pass["passTypeIdentifier"] = passTypeIdentifier
pass["serialNumber"] = serialNumber
pass["teamIdentifier"] = teamIdentifier
pass["organizationName"] = organizationName
pass["logoText"] = logoText
pass["description"] = description

# add relevancy info
pass["relevantDate"] = eventDateString
pass["locations"] = [{
  "longitude" => event_longitude,
  "latitude" => event_latitude
}]
                  
# put ticket fields together                  
pass["eventTicket"] = {
  "headerFields" => headerFields,
  "primaryFields" => primaryFields,
  "secondaryFields" => secondaryFields,
  "auxiliaryFields" => auxiliaryFields,
  "backFields" => backFields
}
                  
# create pass JSON string
passJSON = JSON.pretty_generate(pass)

# get SHA1 of pass JSON
passSHA1 = Digest::SHA1.hexdigest passJSON

# files that are possible in pkpass
possibleResources = ['icon.png', 'icon@2x.png', 
                     'thumbnail.png', 'thumbnail@2x.png', 
                     'strip.png', 'strip@2x.png', 
                     'logo.png', 'logo@2x.png', 
                     'background.png', 'background@2x.png']

# filter possible resources with actual files in folder
resources = possibleResources & Dir['*']

# first file is the JSON 
manifest = {"pass.json" => passSHA1}

# keep track of files to put in ZIP
zipCommand = ["zip", "-q", passFileName, "pass.json", "signature", "manifest.json"]

# iterate over resources
resources.each do |resource_file|
  # load file contents into variable
  file = File.open(resource_file, "rb")
  contents = file.read
  
  # get resource SHA1
  contents_SHA1 = Digest::SHA1.hexdigest contents
  
  # add resource file and SHA1 to manifest hash
  manifest[resource_file] = contents_SHA1
  zipCommand << resource_file
end

# create manifest JSON string
manifestJSON = JSON.pretty_generate(manifest)

# write manifest to disk
manifestFile = open("manifest.json", "w") 
manifestFile.write(manifestJSON)
manifestFile.close

# write pass file to disk
passFile = open("pass.json", "w")
passFile.write(passJSON)
passFile.close

# create signature
signature = OpenSSL::PKCS7.sign(certificate, privateKey, manifestJSON, 
                                [rootCert], 
                                OpenSSL::PKCS7::BINARY | OpenSSL::PKCS7::DETACHED).to_der

# write signature to disk
signatureFile = open("signature", "wb")
signatureFile.write signature
signatureFile.close

# execute zip command
system(*zipCommand)
