from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def home():
    """
    Returns a simple greeting.
    """
    return "Hello, DevOps World!"

@app.route('/health')
def health_check():
    """
    Returns a simple health check status.
    """
    return jsonify({"status": "healthy"})

if __name__ == '__main__':
    # Binds to 0.0.0.0 to be accessible from outside the container
    app.run(host='0.0.0.0', port=5000)