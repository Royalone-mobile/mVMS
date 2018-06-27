class WelcomeController < ApplicationController
  # before_action :authenticate_user!

  def index
  end

  def visitor_sign_form

  end

  def visitors

  end

  def visitor_signout
    if params[:visitor_id]
      @visitor = Visitor.find(params[:visitor_id])
      @visitor.last_visit.update_attributes({sign_out_date: Time.now })
      redirect_to root_path
      return
    end
    @visitors = Visitor.joins(:visitor_visit_informations).merge(VisitorVisitInformation.where(sign_out_date: nil))
    if request.post?
      name = params[:name]
      @visitor = @visitors.where(name: name).first
      if @visitor.nil?
        flash[:error] = 'No Visitor found with this name'
        redirect_to "/visitor_signout"
      end
    end

  end

  def update_visitor
    visitor = Visitor.find_by_id params[:record_visit_id]
    if visitor
      last_visit = visitor.last_visit
      last_visit.sign_out_date = Time.at(params[:record_datetime_out][0..-4].to_i)
      last_visit.visit_reason =  params[:record_reason]
      last_visit.classified =  params[:classified] == 'yes'
      last_visit.us_citizen =  params[:citizen]== 'yes'
      last_visit.person_visiting_id = Person.find_by_name( params[:person_visiting]).id
      last_visit.recorded_by = current_user.full_name
      last_visit.save
    end
    redirect_to '/admin'
  end
  def visitor_bye

  end

  def check_visitor
    visitor = Visitor.where({
                                email: params[:email].to_s.strip
                            }).first_or_initialize
    json = if params[:first_visit].to_s == 'false' and visitor.persisted?
             {success: true}
           elsif params[:first_visit].to_s == 'true' and visitor.persisted?
             {success: false, message: "It seems that this is not your first visit. You can update your data."}
           elsif params[:first_visit].to_s == 'false' and visitor.new_record?
             {success: false, message: "We didn't find your email in our DB, we will create a new record. "}
           else
             {success: true}
           end
    json.merge!({
                    phone: visitor.phone,
                    company: visitor.company,
                    name: visitor.name,
                    us_citizen: visitor.us_citizen?
                })
      render json:  json
  end

  def create_visitor
    visitor = Visitor.where({
                                email: params[:email].to_s.strip
                            }).first_or_initialize
    if params[:update_contact].to_s == 'true' or visitor.new_record?
        visitor.attributes = {
            phone: params[:phone],
            company: params[:company],
            name: params[:person_name],
            us_citizen: params[:us_citizen],
            person_signature: params[:person_signature],
            avatar: params[:person_image_url]
        }
    end
    visitor.save
    if visitor.persisted?
      visitor.visitor_visit_informations.create({
                                                    visit_reason: params[:reason],
                                                    classified: params[:classified],
                                                    person_visiting_id: Person.find_by_name(params[:person_visiting]).try(:id),
                                                    sign_in_date: Time.now
                                                })
      render json: {success: true, visitor: visitor.id }
    else
      render json: {success: false, errors: visitor.errors.full_messages  }
    end

  end

  def visitor_badge
    @visitor = Visitor.find(params[:visitor_id])
  end
end
