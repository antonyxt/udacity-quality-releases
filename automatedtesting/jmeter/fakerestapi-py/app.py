from flask import Flask, jsonify, request, abort

app = Flask(__name__)

# ===== Pre-populated in-memory data =====
# ===== Pre-populated in-memory data (25 items each) =====
books = [
    {"id": i, "title": f"Book {i}", "description": f"Description for book {i}", "pageCount": 100 + i*10,
     "excerpt": f"Excerpt {i}", "publishDate": f"2020-{i:02d}-01T00:00:00Z"} for i in range(1, 26)
]

authors = [
    {"id": i, "firstName": f"AuthorFirst{i}", "lastName": f"AuthorLast{i}"} for i in range(1, 26)
]

users = [
    {"id": i, "userName": f"user{i}"} for i in range(1, 26)
]

activities = [
    {"id": i, "title": f"Activity {i}", "dueDate": f"2025-12-{i:02d}T00:00:00Z", "completed": i % 2 == 0} for i in range(1, 26)
]

# ===== Utility Functions =====
def get_next_id(data_list):
    return max([item["id"] for item in data_list], default=0) + 1

def find_item(data_list, item_id):
    return next((item for item in data_list if item["id"] == item_id), None)

# ===== Books Endpoints =====
@app.route("/api/v1/Books", methods=["GET"])
def get_books():
    return jsonify(books)

@app.route("/api/v1/Books/<int:book_id>", methods=["GET"])
def get_book(book_id):
    book = find_item(books, book_id)
    if book:
        return jsonify(book)
    abort(404)

@app.route("/api/v1/Books", methods=["POST"])
def create_book():
    data = request.get_json()
    book = {"id": get_next_id(books), **data}
    books.append(book)
    return jsonify(book), 201

@app.route("/api/v1/Books/<int:book_id>", methods=["PUT"])
def update_book(book_id):
    book = find_item(books, book_id)
    if not book:
        abort(404)
    data = request.get_json()
    book.update(data)
    return jsonify(book)

@app.route("/api/v1/Books/<int:book_id>", methods=["DELETE"])
def delete_book(book_id):
    book = find_item(books, book_id)
    if not book:
        abort(404)
    books.remove(book)
    return '', 204

# ===== Authors Endpoints =====
@app.route("/api/v1/Authors", methods=["GET"])
def get_authors():
    return jsonify(authors)

@app.route("/api/v1/Authors/<int:author_id>", methods=["GET"])
def get_author(author_id):
    author = find_item(authors, author_id)
    if author:
        return jsonify(author)
    abort(404)

@app.route("/api/v1/Authors", methods=["POST"])
def create_author():
    data = request.get_json()
    author = {"id": get_next_id(authors), **data}
    authors.append(author)
    return jsonify(author), 201

@app.route("/api/v1/Authors/<int:author_id>", methods=["PUT"])
def update_author(author_id):
    author = find_item(authors, author_id)
    if not author:
        abort(404)
    data = request.get_json()
    author.update(data)
    return jsonify(author)

@app.route("/api/v1/Authors/<int:author_id>", methods=["DELETE"])
def delete_author(author_id):
    author = find_item(authors, author_id)
    if not author:
        abort(404)
    authors.remove(author)
    return '', 204

# ===== Users Endpoints =====
@app.route("/api/v1/Users", methods=["GET"])
def get_users():
    return jsonify(users)

@app.route("/api/v1/Users/<int:user_id>", methods=["GET"])
def get_user(user_id):
    user = find_item(users, user_id)
    if user:
        return jsonify(user)
    abort(404)

@app.route("/api/v1/Users", methods=["POST"])
def create_user():
    data = request.get_json()
    user = {"id": get_next_id(users), **data}
    users.append(user)
    return jsonify(user), 201

@app.route("/api/v1/Users/<int:user_id>", methods=["PUT"])
def update_user(user_id):
    user = find_item(users, user_id)
    if not user:
        abort(404)
    data = request.get_json()
    user.update(data)
    return jsonify(user)

@app.route("/api/v1/Users/<int:user_id>", methods=["DELETE"])
def delete_user(user_id):
    user = find_item(users, user_id)
    if not user:
        abort(404)
    users.remove(user)
    return '', 204

# ===== Activities Endpoints =====
@app.route("/api/v1/Activities", methods=["GET"])
def get_activities():
    return jsonify(activities)

@app.route("/api/v1/Activities/<int:activity_id>", methods=["GET"])
def get_activity(activity_id):
    activity = find_item(activities, activity_id)
    if activity:
        return jsonify(activity)
    abort(404)

@app.route("/api/v1/Activities", methods=["POST"])
def create_activity():
    data = request.get_json()
    activity = {"id": get_next_id(activities), **data}
    activities.append(activity)
    return jsonify(activity), 201

@app.route("/api/v1/Activities/<int:activity_id>", methods=["PUT"])
def update_activity(activity_id):
    activity = find_item(activities, activity_id)
    if not activity:
        abort(404)
    data = request.get_json()
    activity.update(data)
    return jsonify(activity)

@app.route("/api/v1/Activities/<int:activity_id>", methods=["DELETE"])
def delete_activity(activity_id):
    activity = find_item(activities, activity_id)
    if not activity:
        abort(404)
    activities.remove(activity)
    return '', 204

# ===== Run Flask App =====
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
