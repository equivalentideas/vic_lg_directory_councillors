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
        .gsub(/[(]By-election.*[)]/, "") # strip by-election text
        .strip

  simplify_name(string)
end

def scrape_council(url)
  agent = Mechanize.new
  page = agent.get(url)

  council = page.at(".elections h2").next_element.text.split(" is ").first.strip

  contact_keys = page.at(".council-profile-contact-information")
                     .search(".council-profile-contact-title")

  website_key = contact_keys.find{ |elm| elm.text == "Web:" }
  website = website_key.next_element.children[0][:href]

  councillor_pars = page.search(".councillors p")
  councillor_pars = councillor_pars.select do |par|
    par.text.include?("- ")
  end

  councillor_pars.each do |element|
    text = element.text

    next if text.include?("Vacancy")

    name = extract_councillor_name(text)

    start_date = if text.include?("By-election")
      Date.parse(text.split("By-election").last.split("(").first.delete(")").strip).to_s
    else
      nil
    end

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
      "name" => name,
      "executive" => position,
      "council_website" => website,
      "start_date" => start_date
    }

    ScraperWiki.save_sqlite(["council", "name"], record)
  end

  no_of_expected_councillors = page.at(".councillors p").text.scan(/\d+/).first.to_i
  no_of_scraped_counillors = ScraperWiki.select("* from data WHERE council ==\"#{council}\"").count

  if no_of_scraped_counillors != no_of_expected_councillors
    puts "#{council}: Number of scraped councillors doesn't match count on page - #{url}\n\n"
  end
end

agent = Mechanize.new

page = agent.get("https://knowyourcouncil.vic.gov.au/councils")

urls = page.at("#myc-council-list").search("a").map {|a| a["href"]}

urls.each {|url| scrape_council(url)}

puts "#{urls.count} councils listed"
puts "#{ScraperWiki.select("* from data group by council").count} councils scraped"
