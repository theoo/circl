namespace :utils do
  desc 'CSV extraction example'
  task :extract => :environment do
    bar = RakeProgressbar.new(Person.all.count)

    path = "doc/extract.csv"

    CSV.open(path, "w", encoding: 'UTF-8') do |csv|
      # header
      csv << ["Persona",
              "Account Number",
              "Organization name",
              "Title",
              "Gender",
              "First name",
              "Last name",
              "Address",
              "Npa town",
              "Country",
              "Phone",
              "Mobile",
              "Email",
              "Second email",
              "Job",
              "Language",
              "Public tag",
              "Private Tag",
              "Date",
              "Received",
              "Fund",
              "Gift Type"]


      # content
      Person.all.each do |p|
        line = []

        receipts = p.receipts

        # First line
        persona = p.is_an_organization? ? "Business" : "Persona"
        line << persona
        line << ""
        line << p.organization_name
        line << p.title

        if p.title
          gender = "female" if ["Madame", "Ms", "Mrs", "Frau", "Mme", "ms", "Mesdames"].index p.title.strip
          gender ||= "male" if ["Monsieur", "Mr", "Mr.", "Herr"].index p.title.strip
        end
        line <<  gender

        line << p.first_name
        line << p.last_name
        line << p.address
        line << p.location.try(:npa_town)
        line << p.location.try(:country).try(:iso_code_a2)
        line << p.phone
        line << p.mobile
        line << p.email
        line << p.second_email
        line << p.job.try(:name)
        line << p.main_communication_language.try(:name)
        line << p.public_tags.map(&:name).join("*")
        line << p.private_tags.map(&:name).join("*")

        if receipts.size > 0 # At least on receipt
          r = receipts.shift
          line << r.value_date.strftime("%d.%m.%y")
          line << r.value.to_f
          line << r.affair.try(:title)
          line << r.means_of_payment
        else # No receipts
          line << ["","","",""]
        end

        csv << line.flatten

        # Next lines (receipts)
        # If there is more than one receipts
        receipts.each do |r|
          line = [persona, "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""]
          line << r.value_date.strftime("%d.%m.%y")
          line << r.value.to_f
          line << r.affair.try(:title)
          line << r.means_of_payment
          csv << line
        end
        bar.inc
      end # Person

      bar.finished

      puts "File saved at #{path}."

    end # CSV


  end
end
