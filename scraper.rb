require 'scraperwiki'
require 'mechanize'
require 'pry'

# Remove councillor whatnot
def simplify_name(text)
  if text.split(" ").first =~ /(Cr|Rt|Mr)/
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
  string = string.split(" - ")[1..-1].join(" - ") # strip pretext
        .gsub(/[(](mayor|deputy|lord).*[)].*$/i, "") # strip position text
        .strip

  simplify_name(string)
end

def scrape_council(url)
  agent = Mechanize.new
  page = agent.get(url)

  council = page.at("h1").inner_text

  contact_keys = page.at(".council-profile-contact-information")
                     .search(".council-profile-contact-title")

  website_key = contact_keys.find{ |elm| elm.text == "Web:" }
  website = website_key.next_element.children[0][:href]

  councillor_pars = page.search(".councillors p")
  councillor_pars = councillor_pars.select do |par|
    par.text.include?(" Cr ") || par.text.include?(" Rt ")
  end

  councillor_pars.each do |element|
    text = element.text

    name = extract_councillor_name(text)

    ward = if text.include?("Unsubdivided") || text.include?("Leadership Team")
      nil
    else
      text.split(" - ")[0].strip
    end

    position = if text.include?("(Mayor") || text.include?("(Lord Mayor")
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

    ScraperWiki.save_sqlite(["council", "councillor"], record)
  end

  # TODO: Do a check against the number of councillors described
  no_of_expected_councillors = page.at(".councillors p").text.scan(/^\d*/).first.to_i
  no_of_scraped_counillors = ScraperWiki.select("* from data WHERE council ==\"#{council}\"").count

  if no_of_scraped_counillors != no_of_expected_councillors
    puts "#{council}: Number of scraped councillors doesn't match count on page - #{url}"
  end
end

agent = Mechanize.new

page = agent.get("https://knowyourcouncil.vic.gov.au/councils")

urls = page.at("#myc-council-list").search("a").map {|a| a["href"]}

urls.each {|url| scrape_council(url)}
