namespace :lighthouse do

  def create_ticket(card, state)
    ticket = Lighthouse::Ticket.new(:project_id => @project.id)
    ticket.title = "##{card.number} #{card.name}"

    # Tags
    priority = card.properties.select{|p| p.attributes["name"] == "Priority"}.first.attributes["value"]
    priority = (priority =~ /critical|high|medium|low/i) ? priority.gsub(/^\d\.\s/, "") : false
    ticket.tags << "#{priority}-priority" if priority
    ticket.tags << "mingle"
    
    # ticket.priority # this can be to an integer in a milestone, maybe later
    Mingle::LIGHTHOUSE_SHARED_TAGS.each do |tag|
      ticket.tags << tag if ticket.title =~ /#{tag.gsub(/\s/, "_")}/i
    end

    update_ticket(ticket, card, state)
  end
  def update_ticket(ticket, card, state)
    card_url = Mingle.card_url + card.number
    link = "[View Ticket on Mingle](#{card_url} \"Mingle Ticket\")"

    ticket.state = state

    if card.description
      card.description.gsub!(/^#\s/, "* ") # change Mingle list to Markdown list
      if ticket.new?
        ticket.body = "## #{link} \n---\n\n" + card.description
      else
        ticket.body = "## #{link} \n---\n\n" + card.description if ticket.original_body == "## #{link} \n---\n\n" + card.description
      end
    end

    ticket.save
  end
  def translate_status(status)
    Mingle::LIGHTHOUSE_STATUS_MAP.assoc(status)[1]
  end

  desc "Delete all 'mingle' tagged tickets"
  task :delete_mingle_tickets do
    @project = Lighthouse::Project.find(LIGHTHOUSE_PROJECT_ID)
    mingle_tickets = @project.tickets( :q => "tagged:mingle" )
    mingle_tickets.each do |ticket|
      @project.delete(:"tickets/" => ticket.id)
      puts "Deleted Ticket [ #{ticket.title} ]"
    end
  end

  desc "Update Tickets/Cards between Mingle and Lighthouse"
  task :sync_mingle => :environment do
    puts "\n"
    puts "-------------------------------"
    puts " Updating lighthouse -> mingle "
    puts "-------------------------------"

    @project = Lighthouse::Project.find(LIGHTHOUSE_PROJECT_ID)
    lighthouse_mingle_tickets = Lighthouse::Ticket.find(:all, :params => { :project_id => @project.id, :q => "tagged:mingle" })
    lighthouse_mingle_tickets.each do |ticket|

      card = Mingle::Card.find(ticket.title.match(/^#(\d*)\s/)[1])
      card_current_status = Mingle::LIGHTHOUSE_STATUS_MAP.assoc( card.properties.select{|p| p.attributes["name"] == "Status"}.first.attributes["value"] )

      if card_current_status and (card_current_status[1] != ticket.state) and (ticket.updated_at > card.modified_on) # if states are different and lighthouse ticket is more recently modified
        if Mingle::LIGHTHOUSE_STATUS_MAP.rassoc(ticket.state)
          new_status = Mingle::LIGHTHOUSE_STATUS_MAP.rassoc(ticket.state)[0]
          Mingle::Card.put(card.number, {:"card[properties][][name]" => "Status", :"card[properties][][value]" => new_status})
          puts "Updating card ##{card.number} status to: #{new_status}"
        else
          puts "Skipped updating card ##{card.number} because I couldn't find a matching status for '#{ticket.state}' state"
        end
      end

    end

    puts "\n\n"
    puts "-------------------------------"
    puts " Updating mingle -> lighthouse "
    puts "-------------------------------"

    card_sets = []

    LIGHTHOUSE_STATUS_MAP.map{|status_map| status_map.first}.each do |status|
      card_sets << [ status, Mingle::Card.find(:all, :params => { :tab => "Current Release", :page => "all", :"filters[]" => "[Status][is][#{status}]" }) ]
    end

    @project = Lighthouse::Project.find(LIGHTHOUSE_PROJECT_ID)
    lighthouse_mingle_tickets = Lighthouse::Ticket.find(:all, :params => { :project_id => @project.id, :q => "tagged:mingle" })

    card_sets.each do |card_set|
      status = card_set[0]
      card_set[1].each do |card|

        exists = false
        lighthouse_ticket = nil

        lighthouse_mingle_tickets.each do |ticket|
          exists, lighthouse_ticket = true, ticket if ticket.title =~ /^##{card.number}/
          break if exists
        end

        if exists
          puts "-- Updating Existing Ticket for Card ##{card.number}"
          update_ticket(lighthouse_ticket, card, translate_status(status))
        elsif status.downcase != "closed" # don't create a new ticket if it is already closed
          puts "-- Creating New Ticket for Card ##{card.number}"
          create_ticket(card, translate_status(status))
        end
      end
    end

  end
end
