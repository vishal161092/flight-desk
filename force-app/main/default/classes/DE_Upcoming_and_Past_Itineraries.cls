public class DE_Upcoming_and_Past_Itineraries {
  @AuraEnabled
  public static List<Custom_Itinerary__c> getItineraryDetails() {
    List<Custom_Itinerary__c> itn = [
      SELECT
        Id,
        Name,
        Itinerary_Name_SubHeading__c,
        Itinerary_Booking_Details__c,
        Itinerary_Label_1__c,
        Itinerary_Label_2__c,
        Itinerary_Label_1_Heading__c,
        Itinerary_Label_2_Heading__c,
        Itinerary_Label_1_SubHeading__c,
        Itinerary_Label_2_SubHeading__c,
        Itinerary_Label_3_Heading__c,
        Itinerary_Label_3_SubHeading__c,
        Itinerary_Label_3_Class_Details__c,
        Itinerary_Button_Name__c,
        Itinerary_Tile_Icon_URL__c,
        Itinerary_Image_URL__c
      FROM Custom_Itinerary__c
      ORDER BY CreatedDate DESC
    ];

    return itn;
  }
  @AuraEnabled
  public static List<Zephyr_Air_Booking_Details__dlm> getBookingDetails() {
    List<Zephyr_Air_Booking_Details__dlm> itn = [
      SELECT bag_tags__c,arrival_destination__c,booking_name__c,last_name__c , flight_status__c ,
       arrival_time__c , club_membership_id__c , flight_class__c, pnr__c , customer_status__c , sno__c , first_name__c  ,
       ffwd__c , departure_destination__c , departure_time__c  FROM  Zephyr_Air_Booking_Details__dlm  ORDER BY sno__c DESC
    ];
    return itn;
  }

  @AuraEnabled
  public static Zephyr_Air_Booking_Details__dlm getRecentBookingDetails() {
    Zephyr_Air_Booking_Details__dlm itn = [
      SELECT bag_tags__c,arrival_destination__c,booking_name__c,last_name__c , flight_status__c ,
       arrival_time__c , club_membership_id__c , flight_class__c, pnr__c , customer_status__c , sno__c , first_name__c  ,
       ffwd__c , departure_destination__c , departure_time__c  FROM  Zephyr_Air_Booking_Details__dlm  ORDER BY sno__c DESC LIMIT 1
    ];
    return itn;
  }

  @AuraEnabled
  public static Zephyr_Air_Loyalty_Details__dlm getLoyaltyDetails() {
    Zephyr_Air_Loyalty_Details__dlm itn = [
      SELECT first_name__c, last_name__c, club_points__c, club_membership_id__c FROM  Zephyr_Air_Loyalty_Details__dlm
    ];
    return itn;
  }

 @AuraEnabled
  public static String updateBookingRecord() {

    Zephyr_Air_Booking_Details_Status__dlm itn = [
      SELECT flight_status__c, arrival_time__c, departure_time__c  FROM  Zephyr_Air_Booking_Details_Status__dlm  WHERE sno__c = 5
    ];

    Booking__c  bk = [SELECT Id, Arrival_Time__c, Departure_Time__c, Status__c FROM Booking__c where Name = 'Booking#000005'];
    bk.Arrival_Time__c = itn.arrival_time__c;
    bk.Departure_Time__c = itn.departure_time__c;
    bk.Status__c = itn.flight_status__c;
    update bk;

    return 'Success';

  }

}