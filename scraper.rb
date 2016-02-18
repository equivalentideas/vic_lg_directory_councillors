require 'scraperwiki'
require 'mechanize'
require 'pry'

# Remove councillor whatnot
def simplify_name(text)
  if text.split(" ").first == "Cr"
    text.split(" ")[1..-1].join(" ")
  else
    text
  end
end

def create_id(council, name)
  components = council + "/" + name
  components.downcase.gsub(" ","_")
end

def extract_councillor_name(string)
  string.sub(/^.*- Cr/, "") # strip pretext
        .gsub(/[(]mayor.*[)].*$/i, "") # strip position text
        .strip
end

def scrape_council(url)
  agent = Mechanize.new
  page = agent.get(url)

  council = page.at("h1").inner_text

  contact_keys = page.at(".council-profile-contact-information")
                     .search(".council-profile-contact-title")

  website_key = contact_keys.find{ |elm| elm.text == "Web:" }
  website = website_key.next_element.children[0][:href]

  councillor_list_elements = page.search(".councillors p")
                                 .select { |elm| elm.text.include?(" Cr ") }
  # Do a check against the number of councillors described

  councillor_list_elements.each do |element|
    text = element.text

    name = extract_councillor_name(text)

    ward = if text.include? "Unsubdivided"
      nil
    else
      text.split(" - ")[0].strip
    end

    position = if text.include?("(Mayor")
      "mayor"
    elsif text.include?("(Deputy")
      "deputy mayor"
    else
       nil
    end

    record = {
      "id" => create_id(council, name),
      "council" => council,
      "ward" => ward,
      "councillor" => name,
      "position" => position,
      "council_website" => website
    }

    p record

    ScraperWiki.save_sqlite(["council", "councillor"], record)
  end
end

agent = Mechanize.new

page = agent.get("https://knowyourcouncil.vic.gov.au/councils")

urls = page.at("#myc-council-list").search("a").map {|a| a["href"]}

urls.each {|url| scrape_council(url)}
