from typing import Any, Text, Dict, List
from rasa_sdk import Action, Tracker
from rasa_sdk.executor import CollectingDispatcher
import json
from nltk.metrics.distance import edit_distance
from _datetime import datetime, timedelta


def get_opening_hours():
    with open("../data/opening_hours.json") as file:
        openingHoursData:dict = json.load(file)["items"]
    return openingHoursData


def get_menu():
    with open("../data/menu.json") as file:
        menuData = json.load(file)["items"]
    return menuData


opening_hours = get_opening_hours()
menu = get_menu()
list_of_orders = []

class ActionRespondGreeting(Action):
    def name(self) -> Text:
        return "respond_greeting"

    def run(self, dispatcher: CollectingDispatcher, tracker: Tracker, domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        dispatcher.utter_message(template="utter_greet")
        return []


class ActionRespondOpeningHours(Action):
    def name(self) -> Text:
        return "respond_opening_hours"

    def run(self, dispatcher: CollectingDispatcher, tracker: Tracker, domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        entities = tracker.latest_message.get("entities", [])
        requested_day = next((entity["value"] for entity in entities if entity["entity"] == "day"), None)

        if requested_day and requested_day in opening_hours:
            hours = opening_hours[requested_day]
            opening_time = hours['open']
            closing_time = hours['close']
            message = f"The restaurant is open on {requested_day} from {opening_time} to {closing_time}."
        else:
            message = "I'm sorry, I couldn't find the opening hours for that day."

        dispatcher.utter_message(text=message)
        return []


class ActionListMenuItems(Action):
    def name(self) -> Text:
        return "list_menu_items"

    def run(self, dispatcher: CollectingDispatcher, tracker: Tracker, domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        if menu:
            menu_message = "Here are our menu items:\n"
            for item in menu:
                name = item["name"]
                price = item["price"]
                menu_message += f"{name} for {price} USD\n"
            dispatcher.utter_message(text=menu_message)
        else:
            menu_message = "I'm sorry, the menu is currently unavailable."

        dispatcher.utter_message(text=menu_message)
        return []


class ActionProcessOrder(Action):
    def name(self) -> Text:
        return "action_process_order"

    def run(self, dispatcher: CollectingDispatcher, tracker: Tracker, domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        entities = tracker.latest_message.get("entities", [])
        item = next((entity["value"] for entity in entities if entity["entity"] == "item"), None)
        special_requests = next((entity["value"] for entity in entities if entity["entity"] == "special_requirement"), None)

        if item is None:
            dispatcher.utter_message(text="I didn't understand what you say.")
            return []
        meal_in_menu = self.find_meal(item)

        if meal_in_menu is None:
            dispatcher.utter_message(text=f"We currently not selling {item}")
            return []

        if special_requests is None:
            special_requests = ""

        list_of_orders.append(
            {
                "id": len(list_of_orders),
                "name": meal_in_menu["name"],
                "price": meal_in_menu["price"],
                "preparation_time": meal_in_menu["preparation_time"],
                "ready_at": datetime.now() + timedelta(hours=meal_in_menu["preparation_time"]),
                "special_request": special_requests,
                "pickup_or_delivery": "Pick-up on place."
            }
        )
        message = "Your order has been placed. You order: "
        total_price = 0
        for item in list_of_orders:
            name = item["name"]
            total_price += item["price"]
            special_requests = item["special_request"]
            ready_at = item["ready_at"]
            message += f"{name} {special_requests} - ready at {ready_at}\n"
        message += f"Your total price is {total_price} USD\n"
        message += "Would you like to provide your delivery address?"
        dispatcher.utter_message(text=message)
        return []

    def find_meal(self,meal_name):
        for meal in menu:
            if meal["name"].lower() == meal_name.lower():
                return {
                    "name": meal["name"],
                    "price": meal["price"],
                    "preparation_time": meal["preparation_time"]
                }
        best_distance = 99999
        best_meal = None
        for meal in menu:
            distance = edit_distance(meal_name.lower(), meal["name"].lower())
            if distance < best_distance:
                best_distance = distance
                best_meal = meal
        if best_distance < 3:
            return best_meal
        return None

class ActionProvideDeliveryAddress(Action):
    def name(self) -> Text:
        return "confirm_delivery_address"

    def run(self, dispatcher: CollectingDispatcher, tracker: Tracker, domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        entities = tracker.latest_message.get("entities", [])
        delivery_address = next((entity["value"] for entity in entities if entity["entity"] == "delivery_address"), None)

        if delivery_address is None:
            dispatcher.utter_message(text=f"We are waiting for you in restaurant!")
        else:
            dispatcher.utter_message(text=f"Thank you! Your delivery will be sent to {delivery_address}.")
            list_of_orders[-1]["pickup_or_delivery"] = f"Delivery at {delivery_address}."

        return []

class ActionGetOrderedMeal(Action):
    def name(self) -> Text:
        return "respond_get_ordered_meal"

    def run(self, dispatcher: CollectingDispatcher,tracker: Tracker,domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        message = "Your orders:\n"
        for item in list_of_orders:
            name = item["name"]
            special_requests = item["special_request"]
            pickup_or_delivery = item["pickup_or_delivery"]
            ready_at = item["ready_at"]
            message += f"{name} {special_requests} - will be ready at {ready_at}. {pickup_or_delivery}\n"
        dispatcher.utter_message(text=f"{message}\n")
        return []

class ActionResponseGoodbye(Action):
    def name(self) -> Text:
        return "respond_goodbye"

    def run(self, dispatcher: CollectingDispatcher,tracker: Tracker,domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        list_of_orders.clear()
        dispatcher.utter_message(text="Goodbye! See you again!")
        return []