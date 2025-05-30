from flask import Flask, render_template, request, redirect, url_for, flash, jsonify
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user, current_user
import firebase_admin
from firebase_admin import credentials, firestore, auth
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize Flask app
app = Flask(__name__)
app.secret_key = os.getenv('SECRET_KEY', 'your-secret-key-here')

# Initialize Firebase Admin
cred = credentials.Certificate({
    "type": "service_account",
    "project_id": "daddy-ecom-store",
    "private_key_id": os.getenv('FIREBASE_PRIVATE_KEY_ID'),
    "private_key": os.getenv('FIREBASE_PRIVATE_KEY').replace('\\n', '\n'),
    "client_email": os.getenv('FIREBASE_CLIENT_EMAIL'),
    "client_id": os.getenv('FIREBASE_CLIENT_ID'),
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": os.getenv('FIREBASE_CLIENT_CERT_URL')
})

firebase_admin.initialize_app(cred)
db = firestore.client()

# Initialize Flask-Login
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'

# User class for Flask-Login
class User(UserMixin):
    def __init__(self, uid, email, role):
        self.id = uid
        self.email = email
        self.role = role

@login_manager.user_loader
def load_user(user_id):
    try:
        user = auth.get_user(user_id)
        # Get user role from Firestore
        user_doc = db.collection('buyers').document(user_id).get()
        if user_doc.exists:
            return User(user_id, user.email, 'buyer')
        user_doc = db.collection('vendors').document(user_id).get()
        if user_doc.exists:
            return User(user_id, user.email, 'vendor')
        user_doc = db.collection('couriers').document(user_id).get()
        if user_doc.exists:
            return User(user_id, user.email, 'courier')
        return None
    except:
        return None

# Routes
@app.route('/')
def home():
    # Get categories with product count
    categories = []
    for doc in db.collection('categories').stream():
        category_data = doc.to_dict()
        # Get product count for this category
        product_count = len(list(db.collection('products')
                               .where('category', '==', category_data.get('categoryName', ''))
                               .stream()))
        categories.append({
            'id': doc.id,
            'name': category_data.get('categoryName', ''),
            'icon': category_data.get('icon', 'shopping-bag'),
            'imageUrl': category_data.get('image', 'https://via.placeholder.com/300x200?text=Category'),
            'product_count': product_count
        })

    # Get featured products
    featured_products = list(db.collection('products')
                           .where('is_featured', '==', True)
                           .limit(8)
                           .stream())
    featured_products = [{
        'id': doc.id,
        'productName': doc.to_dict().get('productName', ''),
        'productPrice': doc.to_dict().get('productPrice', 0.0),
        'brandName': doc.to_dict().get('brandName', ''),
        'imageUrlList': doc.to_dict().get('imageUrlList', []),
        'rating': doc.to_dict().get('rating', 0.0),
        'reviewCount': doc.to_dict().get('reviewCount', 0),
        'productDescription': doc.to_dict().get('productDescription', ''),
        'category': doc.to_dict().get('category', ''),
        'quantity': doc.to_dict().get('quantity', 0)
    } for doc in featured_products]

    # Get all products
    all_products = list(db.collection('products').stream())
    all_products = [{
        'id': doc.id,
        'productName': doc.to_dict().get('productName', ''),
        'productPrice': doc.to_dict().get('productPrice', 0.0),
        'brandName': doc.to_dict().get('brandName', ''),
        'imageUrlList': doc.to_dict().get('imageUrlList', []),
        'rating': doc.to_dict().get('rating', 0.0),
        'reviewCount': doc.to_dict().get('reviewCount', 0),
        'productDescription': doc.to_dict().get('productDescription', ''),
        'category': doc.to_dict().get('category', ''),
        'quantity': doc.to_dict().get('quantity', 0)
    } for doc in all_products]

    return render_template('customer/home.html',
                         categories=categories,
                         featured_products=featured_products,
                         all_products=all_products)

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form.get('email')
        password = request.form.get('password')
        
        # Special case for admin login
        if email == 'admin@admin' and password == 'admin':
            try:
                # Check if admin exists in Firebase
                admin_doc = db.collection('admins').document('admin').get()
                if not admin_doc.exists:
                    # Create admin document if it doesn't exist
                    db.collection('admins').document('admin').set({
                        'email': 'admin@admin',
                        'role': 'admin',
                        'createdAt': firestore.SERVER_TIMESTAMP
                    })
                
                # Create admin user object
                admin_user = User('admin', 'admin@admin', 'admin')
                login_user(admin_user)
                return redirect(url_for('admin_dashboard'))
            except Exception as e:
                flash('Admin login failed', 'danger')
                return redirect(url_for('login'))
        
        try:
            # Regular user login
            user = auth.get_user_by_email(email)
            user_obj = load_user(user.uid)
            if user_obj:
                login_user(user_obj)
                if user_obj.role == 'buyer':
                    return redirect(url_for('buyer_dashboard'))
                elif user_obj.role == 'vendor':
                    return redirect(url_for('vendor_dashboard'))
                elif user_obj.role == 'courier':
                    return redirect(url_for('courier_dashboard'))
                elif user_obj.role == 'admin':
                    return redirect(url_for('admin_dashboard'))
        except:
            flash('Invalid email or password', 'danger')
    return render_template('login.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        email = request.form.get('email')
        password = request.form.get('password')
        full_name = request.form.get('full_name')
        phone_number = request.form.get('phone_number')
        try:
            user = auth.create_user(
                email=email,
                password=password
            )
            # Create user document in Firestore
            db.collection('buyers').document(user.uid).set({
                'email': email,
                'fullName': full_name,
                'phoneNumber': phone_number,
                'uid': user.uid,
                'address': '',
                'profileImage': '',
                'createdAt': firestore.SERVER_TIMESTAMP,
                'updatedAt': firestore.SERVER_TIMESTAMP,
            })
            flash('Registration successful! Please login.', 'success')
            return redirect(url_for('login'))
        except Exception as e:
            flash(f'Registration failed: {str(e)}', 'danger')
    return render_template('register.html')

@app.route('/dashboard')
@login_required
def dashboard():
    if current_user.role == 'buyer':
        return render_template('buyer_dashboard.html')
    elif current_user.role == 'vendor':
        return render_template('vendor_dashboard.html')
    elif current_user.role == 'courier':
        return render_template('courier_dashboard.html')
    return redirect(url_for('home'))

@app.route('/logout')
@login_required
def logout():
    logout_user()
    flash('You have been logged out successfully.', 'success')
    return redirect(url_for('home'))

# Add admin dashboard route
@app.route('/admin/dashboard')
@login_required
def admin_dashboard():
    if current_user.role != 'admin':
        flash('Access denied', 'danger')
        return redirect(url_for('home'))
    
    # Get statistics for admin dashboard
    total_users = len(list(db.collection('buyers').stream()))
    total_vendors = len(list(db.collection('vendors').stream()))
    total_orders = len(list(db.collection('orders').stream()))
    total_revenue = 0  # You'll need to calculate this from orders
    
    # Get pending vendors
    pending_vendors = list(db.collection('vendors').where('status', '==', 'pending').stream())
    
    # Get all users
    users = []
    for collection in ['buyers', 'vendors', 'couriers']:
        for doc in db.collection(collection).stream():
            user_data = doc.to_dict()
            users.append({
                'id': doc.id,
                'name': user_data.get('fullName', 'N/A'),
                'email': user_data.get('email', 'N/A'),
                'role': collection[:-1],  # Remove 's' from end
                'is_active': user_data.get('status', 'active') == 'active',
                'created_at': user_data.get('createdAt', None)
            })
    
    return render_template('admin/admin_dashboard.html',
                         total_users=total_users,
                         total_vendors=total_vendors,
                         total_orders=total_orders,
                         total_revenue=total_revenue,
                         pending_vendors=pending_vendors,
                         users=users)

# Add other dashboard routes
@app.route('/buyer/dashboard')
@login_required
def buyer_dashboard():
    if current_user.role != 'buyer':
        flash('Access denied', 'danger')
        return redirect(url_for('home'))
    
    # Get categories with product count
    categories = []
    for doc in db.collection('categories').stream():
        category_data = doc.to_dict()
        # Get product count for this category
        product_count = len(list(db.collection('products')
                               .where('category', '==', category_data.get('categoryName', ''))
                               .stream()))
        categories.append({
            'id': doc.id,
            'name': category_data.get('categoryName', ''),
            'icon': category_data.get('icon', 'shopping-bag'),
            'product_count': product_count
        })
    
    # Get featured products
    featured_products = list(db.collection('products')
                           .where('is_featured', '==', True)
                           .limit(8)
                           .stream())
    featured_products = [{
        'id': doc.id,
        'productName': doc.to_dict().get('productName', ''),
        'productPrice': doc.to_dict().get('productPrice', 0.0),
        'brandName': doc.to_dict().get('brandName', ''),
        'imageUrlList': doc.to_dict().get('imageUrlList', []),
        'rating': doc.to_dict().get('rating', 0.0),
        'reviewCount': doc.to_dict().get('reviewCount', 0),
        'productDescription': doc.to_dict().get('productDescription', ''),
        'category': doc.to_dict().get('category', ''),
        'quantity': doc.to_dict().get('quantity', 0)
    } for doc in featured_products]
    
    # Get all products
    all_products = list(db.collection('products').stream())
    all_products = [{
        'id': doc.id,
        'productName': doc.to_dict().get('productName', ''),
        'productPrice': doc.to_dict().get('productPrice', 0.0),
        'brandName': doc.to_dict().get('brandName', ''),
        'imageUrlList': doc.to_dict().get('imageUrlList', []),
        'rating': doc.to_dict().get('rating', 0.0),
        'reviewCount': doc.to_dict().get('reviewCount', 0),
        'productDescription': doc.to_dict().get('productDescription', ''),
        'category': doc.to_dict().get('category', ''),
        'quantity': doc.to_dict().get('quantity', 0)
    } for doc in all_products]
    
    return render_template('customer/home.html',
                         categories=categories,
                         featured_products=featured_products,
                         all_products=all_products)

@app.route('/vendor/dashboard')
@login_required
def vendor_dashboard():
    if current_user.role != 'vendor':
        flash('Access denied', 'danger')
        return redirect(url_for('home'))
    
    # Get vendor statistics
    vendor_doc = db.collection('vendors').document(current_user.id).get()
    vendor_data = vendor_doc.to_dict() if vendor_doc.exists else {}
    
    # Get vendor's products
    products = list(db.collection('products').where('vendor_id', '==', current_user.id).stream())
    
    # Get vendor's orders
    orders = list(db.collection('orders').where('vendorId', '==', current_user.id).stream())
    
    total_sales = sum(order.get('totalAmount', 0) for order in orders)
    total_orders = len(orders)
    total_products = len(products)
    pending_orders = len([order for order in orders if order.get('status') == 'pending'])
    
    return render_template('vendor/vendor_dashboard.html',
                         total_sales=total_sales,
                         total_orders=total_orders,
                         total_products=total_products,
                         pending_orders=pending_orders,
                         products=products,
                         recent_orders=orders[:5])  # Show only 5 most recent orders

@app.route('/courier/dashboard')
@login_required
def courier_dashboard():
    if current_user.role != 'courier':
        flash('Access denied', 'danger')
        return redirect(url_for('home'))
    return render_template('delivery/courier_dashboard.html')

# Add cart API endpoint
@app.route('/api/cart/add', methods=['POST'])
@login_required
def add_to_cart():
    if current_user.role != 'buyer':
        return jsonify({'success': False, 'message': 'Access denied'}), 403
    
    data = request.get_json()
    product_id = data.get('product_id')
    quantity = data.get('quantity', 1)
    size = data.get('size')
    
    try:
        # Get product details
        product_doc = db.collection('products').document(product_id).get()
        if not product_doc.exists:
            return jsonify({'success': False, 'message': 'Product not found'}), 404
        
        product_data = product_doc.to_dict()
        
        # Check if product is in stock
        if product_data.get('quantity', 0) < quantity:
            return jsonify({'success': False, 'message': 'Not enough stock available'}), 400
        
        # Add to cart in Firestore
        cart_ref = db.collection('users').document(current_user.id).collection('cart').document(product_id)
        cart_ref.set({
            'productId': product_id,
            'productName': product_data.get('productName'),
            'productPrice': product_data.get('productPrice'),
            'imageUrl': product_data.get('imageUrlList', [''])[0],
            'quantity': quantity,
            'size': size,
            'vendorId': product_data.get('vendorId'),
            'addedAt': firestore.SERVER_TIMESTAMP
        }, merge=True)
        
        return jsonify({
            'success': True,
            'message': 'Product added to cart successfully'
        })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

# Add search endpoint
@app.route('/search')
def search():
    query = request.args.get('q', '').strip()
    if not query:
        return redirect(url_for('home'))
    
    try:
        # Search products by name, brand, or category
        products_query = db.collection('products')
        products = []
        
        # Get all products and filter in Python to allow for partial matches
        all_products = list(products_query.stream())
        for doc in all_products:
            product_data = doc.to_dict()
            # Check if query matches product name, brand, or category (case insensitive)
            if (query.lower() in product_data.get('productName', '').lower() or
                query.lower() in product_data.get('brandName', '').lower() or
                query.lower() in product_data.get('category', '').lower()):
                products.append({
                    'id': doc.id,
                    'productName': product_data.get('productName', ''),
                    'productPrice': product_data.get('productPrice', 0.0),
                    'brandName': product_data.get('brandName', ''),
                    'imageUrlList': product_data.get('imageUrlList', []),
                    'rating': product_data.get('rating', 0.0),
                    'reviewCount': product_data.get('reviewCount', 0),
                    'productDescription': product_data.get('productDescription', ''),
                    'category': product_data.get('category', ''),
                    'quantity': product_data.get('quantity', 0)
                })
        
        # Sort products by relevance (exact matches first)
        products.sort(key=lambda x: (
            query.lower() not in x['productName'].lower(),  # Exact matches in name first
            query.lower() not in x['brandName'].lower(),    # Then brand matches
            query.lower() not in x['category'].lower()      # Then category matches
        ))
        
        return render_template('customer/search_results.html', 
                             products=products, 
                             query=query,
                             result_count=len(products))
                             
    except Exception as e:
        flash(f'Error performing search: {str(e)}', 'danger')
        return redirect(url_for('home'))

@app.route('/cart')
@login_required
def cart():
    if current_user.role != 'buyer':
        flash('Access denied', 'danger')
        return redirect(url_for('home'))
    
    # Get cart items
    cart_items = list(db.collection('users').document(current_user.id).collection('cart').stream())
    cart_products = []
    subtotal = 0
    shipping_total = 0
    
    for item in cart_items:
        item_data = item.to_dict()
        product_doc = db.collection('products').document(item_data['productId']).get()
        if product_doc.exists:
            product_data = product_doc.to_dict()
            vendor_doc = db.collection('vendors').document(product_data.get('vendorId')).get()
            vendor_data = vendor_doc.to_dict() if vendor_doc.exists else {}
            
            item_total = item_data.get('productPrice', 0) * item_data.get('quantity', 1)
            shipping_charge = product_data.get('shippingCharge', 0) if product_data.get('chargeShipping', False) else 0
            
            cart_products.append({
                'id': item.id,
                'productId': item_data.get('productId'),
                'name': item_data.get('productName'),
                'price': item_data.get('productPrice', 0),
                'image': item_data.get('imageUrl'),
                'quantity': item_data.get('quantity', 1),
                'size': item_data.get('size'),
                'vendor_name': vendor_data.get('bussinessName', 'Unknown Vendor'),
                'item_total': item_total,
                'shipping_charge': shipping_charge
            })
            
            subtotal += item_total
            shipping_total += shipping_charge
    
    total = subtotal + shipping_total
    
    return render_template('customer/cart.html', 
                         cart_items=cart_products,
                         subtotal=subtotal,
                         shipping_total=shipping_total,
                         total=total)

@app.route('/api/cart/update', methods=['POST'])
@login_required
def update_cart():
    if current_user.role != 'buyer':
        return jsonify({'success': False, 'message': 'Access denied'}), 403
    
    data = request.get_json()
    product_id = data.get('product_id')
    quantity = data.get('quantity', 1)
    
    try:
        if quantity <= 0:
            # Remove item from cart
            db.collection('users').document(current_user.id).collection('cart').document(product_id).delete()
        else:
            # Update quantity
            db.collection('users').document(current_user.id).collection('cart').document(product_id).update({
                'quantity': quantity
            })
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/cart/remove', methods=['POST'])
@login_required
def remove_from_cart():
    if current_user.role != 'buyer':
        return jsonify({'success': False, 'message': 'Access denied'}), 403
    
    data = request.get_json()
    product_id = data.get('product_id')
    
    try:
        db.collection('users').document(current_user.id).collection('cart').document(product_id).delete()
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/checkout')
@login_required
def checkout():
    if current_user.role != 'buyer':
        flash('Access denied', 'danger')
        return redirect(url_for('home'))
    
    # Get cart items
    cart_items = list(db.collection('users').document(current_user.id).collection('cart').stream())
    cart_products = []
    totalAmount = 0
    
    for item in cart_items:
        item_data = item.to_dict()
        product_doc = db.collection('products').document(item_data['productId']).get()
        if product_doc.exists:
            product_data = product_doc.to_dict()
            cart_products.append({
                'productId': item_data['productId'],
                'productName': product_data.get('productName'),
                'price': product_data.get('productPrice', 0),
                'imageUrl': product_data.get('imageUrlList', [''])[0],
                'quantity': item_data.get('quantity', 1),
                'size': item_data.get('size'),
                'vendorId': product_data.get('vendorId')
            })
            totalAmount += product_data.get('productPrice', 0) * item_data.get('quantity', 1)
    
    # Get user's shipping address
    user_doc = db.collection('buyers').document(current_user.id).get()
    user_data = user_doc.to_dict() if user_doc.exists else {}
    
    return render_template('customer/checkout.html', 
                         cart_items=cart_products, 
                         totalAmount=totalAmount,
                         user_data=user_data)

@app.route('/orders')
@login_required
def orders():
    if current_user.role != 'buyer':
        flash('Access denied', 'danger')
        return redirect(url_for('home'))
    
    # Get user's orders
    orders = list(db.collection('orders')
                 .where('buyerId', '==', current_user.id)
                 .stream())
    
    orders_list = []
    for order in orders:
        # Convert Firestore document to dictionary
        order_dict = order.to_dict()
        
        # Create order object with exact field names from Firestore
        order_obj = {
            'orderId': str(order_dict.get('orderId', '')),
            'buyerId': str(order_dict.get('buyerId', '')),
            'buyerName': str(order_dict.get('buyerName', '')),
            'buyerPhone': str(order_dict.get('buyerPhone', '')),
            'courierId': str(order_dict.get('courierId', '')),
            'courierName': str(order_dict.get('courierName', '')),
            'createdAt': order_dict.get('createdAt'),
            'pickedUpAt': order_dict.get('pickedUpAt'),
            'paymentMethod': str(order_dict.get('paymentMethod', '')),
            'products': order_dict.get('products', []),
            'shippingAddress': str(order_dict.get('shippingAddress', '')),
            'status': str(order_dict.get('status', '')),
            'totalAmount': float(order_dict.get('totalAmount', 0)),
            'updatedAt': order_dict.get('updatedAt'),
            'vendorId': str(order_dict.get('vendorId', ''))
        }
        orders_list.append(order_obj)
    
    # Sort orders by creation date
    orders_list.sort(key=lambda x: x['createdAt'] if x['createdAt'] else '', reverse=True)
    
    return render_template('customer/orders.html', orders=orders_list)

@app.route('/order/<order_id>')
@login_required
def order_details(order_id):
    if current_user.role != 'buyer':
        flash('Access denied', 'danger')
        return redirect(url_for('home'))
    
    # Get order details
    order_doc = db.collection('orders').document(order_id).get()
    if not order_doc.exists:
        flash('Order not found', 'danger')
        return redirect(url_for('orders'))
    
    order_data = order_doc.to_dict()
    if order_data.get('buyerId') != current_user.id:
        flash('Access denied', 'danger')
        return redirect(url_for('orders'))
    
    # Create order object with exact field names
    order = {
        'orderId': str(order_data.get('orderId', '')),
        'buyerId': str(order_data.get('buyerId', '')),
        'buyerName': str(order_data.get('buyerName', '')),
        'buyerPhone': str(order_data.get('buyerPhone', '')),
        'courierId': str(order_data.get('courierId', '')),
        'courierName': str(order_data.get('courierName', '')),
        'createdAt': order_data.get('createdAt'),
        'pickedUpAt': order_data.get('pickedUpAt'),
        'paymentMethod': str(order_data.get('paymentMethod', '')),
        'products': order_data.get('products', []),
        'shippingAddress': str(order_data.get('shippingAddress', '')),
        'status': str(order_data.get('status', '')),
        'totalAmount': float(order_data.get('totalAmount', 0)),
        'updatedAt': order_data.get('updatedAt'),
        'vendorId': str(order_data.get('vendorId', ''))
    }
    
    return render_template('customer/order_details.html', order=order)

@app.route('/api/order/cancel/<order_id>', methods=['POST'])
@login_required
def cancel_order(order_id):
    if current_user.role != 'buyer':
        return jsonify({'success': False, 'message': 'Access denied'}), 403
    
    try:
        order_doc = db.collection('orders').document(order_id).get()
        if not order_doc.exists:
            return jsonify({'success': False, 'message': 'Order not found'}), 404
        
        order_data = order_doc.to_dict()
        if order_data.get('buyerId') != current_user.id:
            return jsonify({'success': False, 'message': 'Access denied'}), 403
        
        if order_data.get('status') not in ['pending', 'processing']:
            return jsonify({'success': False, 'message': 'Order cannot be cancelled'}), 400
        
        # Update order status
        db.collection('orders').document(order_id).update({
            'status': 'cancelled',
            'updatedAt': firestore.SERVER_TIMESTAMP
        })
        
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

# Add template filters
@app.template_filter('status_color')
def status_color(status):
    colors = {
        'pending': 'warning',
        'processing': 'info',
        'shipped': 'primary',
        'delivered': 'success',
        'cancelled': 'danger',
        'refunded': 'secondary'
    }
    return colors.get(status.lower(), 'secondary')

@app.template_filter('payment_status_color')
def payment_status_color(status):
    colors = {
        'pending': 'warning',
        'paid': 'success',
        'failed': 'danger',
        'refunded': 'secondary'
    }
    return colors.get(status.lower(), 'secondary')

@app.route('/profile', methods=['GET', 'POST'])
@login_required
def profile():
    if request.method == 'POST':
        try:
            # Get form data
            full_name = request.form.get('full_name')
            phone_number = request.form.get('phone_number')
            address = {
                'address': request.form.get('address'),
                'city': request.form.get('city'),
                'state': request.form.get('state'),
                'zip': request.form.get('zip'),
                'country': request.form.get('country')
            }
            
            # Update user profile in Firestore
            user_ref = db.collection('buyers').document(current_user.id)
            user_ref.update({
                'fullName': full_name,
                'phoneNumber': phone_number,
                'address': address,
                'updatedAt': firestore.SERVER_TIMESTAMP
            })
            
            flash('Profile updated successfully', 'success')
            return redirect(url_for('profile'))
        except Exception as e:
            flash(f'Error updating profile: {str(e)}', 'danger')
    
    # Get user data
    user_doc = db.collection('buyers').document(current_user.id).get()
    user_data = user_doc.to_dict() if user_doc.exists else {}
    
    return render_template('customer/profile.html', user=user_data)

@app.route('/profile/change-password', methods=['POST'])
@login_required
def change_password():
    current_password = request.form.get('current_password')
    new_password = request.form.get('new_password')
    confirm_password = request.form.get('confirm_password')
    
    if new_password != confirm_password:
        flash('New passwords do not match', 'danger')
        return redirect(url_for('profile'))
    
    try:
        # Update password in Firebase Auth
        auth.update_user(
            current_user.id,
            password=new_password
        )
        flash('Password updated successfully', 'success')
    except Exception as e:
        flash(f'Error updating password: {str(e)}', 'danger')
    
    return redirect(url_for('profile'))

@app.route('/profile/upload-photo', methods=['POST'])
@login_required
def upload_profile_photo():
    if 'photo' not in request.files:
        flash('No file selected', 'danger')
        return redirect(url_for('profile'))
    
    file = request.files['photo']
    if file.filename == '':
        flash('No file selected', 'danger')
        return redirect(url_for('profile'))
    
    try:
        # Here you would typically upload the file to your storage service
        # For now, we'll just update the profile with a placeholder
        user_ref = db.collection('buyers').document(current_user.id)
        user_ref.update({
            'profileImage': 'https://via.placeholder.com/150',
            'updatedAt': firestore.SERVER_TIMESTAMP
        })
        
        flash('Profile photo updated successfully', 'success')
    except Exception as e:
        flash(f'Error uploading photo: {str(e)}', 'danger')
    
    return redirect(url_for('profile'))

@app.route('/products')
def all_products():
    # Get filter parameters
    sort = request.args.get('sort', 'newest')
    price_range = request.args.get('price_range', '')
    min_rating = request.args.get('rating', '')
    
    # Base query
    products_query = db.collection('products')
    
    # Apply price range filter
    if price_range:
        if price_range == '0-25':
            products_query = products_query.where('productPrice', '<=', 25)
        elif price_range == '25-50':
            products_query = products_query.where('productPrice', '>=', 25).where('productPrice', '<=', 50)
        elif price_range == '50-100':
            products_query = products_query.where('productPrice', '>=', 50).where('productPrice', '<=', 100)
        elif price_range == '100+':
            products_query = products_query.where('productPrice', '>=', 100)
    
    # Apply rating filter
    if min_rating:
        products_query = products_query.where('rating', '>=', float(min_rating))
    
    # Apply sorting
    if sort == 'price_low':
        products_query = products_query.order_by('productPrice')
    elif sort == 'price_high':
        products_query = products_query.order_by('productPrice', direction=firestore.Query.DESCENDING)
    elif sort == 'rating':
        products_query = products_query.order_by('rating', direction=firestore.Query.DESCENDING)
    else:  # newest
        products_query = products_query.order_by('createdAt', direction=firestore.Query.DESCENDING)
    
    # Get products
    products = list(products_query.stream())
    products = [{
        'id': doc.id,
        'productName': doc.to_dict().get('productName', ''),
        'productPrice': doc.to_dict().get('productPrice', 0.0),
        'brandName': doc.to_dict().get('brandName', ''),
        'imageUrlList': doc.to_dict().get('imageUrlList', []),
        'rating': doc.to_dict().get('rating', 0.0),
        'reviewCount': doc.to_dict().get('reviewCount', 0),
        'productDescription': doc.to_dict().get('productDescription', ''),
        'category': doc.to_dict().get('category', ''),
        'quantity': doc.to_dict().get('quantity', 0)
    } for doc in products]
    
    # Get categories for filter sidebar
    categories = list(db.collection('categories').stream())
    categories = [{'id': doc.id, **doc.to_dict()} for doc in categories]
    
    return render_template('customer/all_products.html',
                         products=products,
                         categories=categories,
                         current_sort=sort,
                         current_price_range=price_range,
                         current_rating=min_rating)

@app.route('/category/<category_id>')
def category_products(category_id):
    # Get category details
    category_doc = db.collection('categories').document(category_id).get()
    if not category_doc.exists:
        flash('Category not found', 'danger')
        return redirect(url_for('home'))
    
    category_data = category_doc.to_dict()
    
    # Get products in this category
    products = list(db.collection('products')
                   .where('category', '==', category_data.get('categoryName', ''))
                   .stream())
    
    # Format products to match Flutter structure
    products = [{
        'id': doc.id,
        'productName': doc.to_dict().get('productName', ''),
        'productPrice': doc.to_dict().get('productPrice', 0.0),
        'brandName': doc.to_dict().get('brandName', ''),
        'imageUrlList': doc.to_dict().get('imageUrlList', []),
        'rating': doc.to_dict().get('rating', 0.0),
        'reviewCount': doc.to_dict().get('reviewCount', 0),
        'productDescription': doc.to_dict().get('productDescription', ''),
        'category': doc.to_dict().get('category', ''),
        'quantity': doc.to_dict().get('quantity', 0)
    } for doc in products]
    
    return render_template('customer/category_products.html',
                         category=category_data,
                         products=products)

@app.route('/product/<product_id>')
def product_details(product_id):
    # Get product details
    product_doc = db.collection('products').document(product_id).get()
    if not product_doc.exists:
        flash('Product not found', 'danger')
        return redirect(url_for('home'))
    
    product_data = product_doc.to_dict()
    product_data['id'] = product_id  # Add the document ID to the data
    
    # Get vendor details
    vendor_doc = db.collection('vendors').document(product_data.get('vendorId')).get()
    vendor_data = vendor_doc.to_dict() if vendor_doc.exists else {}
    
    # Get product reviews
    reviews = list(db.collection('products').document(product_id).collection('reviews').stream())
    reviews_list = []
    for review in reviews:
        review_data = review.to_dict()
        reviews_list.append({
            'id': review.id,
            'rating': review_data.get('rating', 0),
            'comment': review_data.get('comment', ''),
            'createdAt': review_data.get('createdAt'),
            'userName': review_data.get('userName', 'Anonymous'),
            'isVerifiedPurchase': review_data.get('isVerifiedPurchase', False),
            'userImage': review_data.get('userImage', '')
        })
    
    # Sort reviews by date (newest first)
    reviews_list.sort(key=lambda x: x['createdAt'] if x['createdAt'] else '', reverse=True)
    
    # Get related products (same category) - Modified to avoid index
    all_products = list(db.collection('products').stream())
    related_products = []
    for doc in all_products:
        doc_data = doc.to_dict()
        if (doc.id != product_id and 
            doc_data.get('category') == product_data.get('category')):
            related_products.append({
                'id': doc.id,
                'productName': doc_data.get('productName', ''),
                'productPrice': doc_data.get('productPrice', 0.0),
                'imageUrlList': doc_data.get('imageUrlList', []),
                'rating': doc_data.get('rating', 0.0),
                'productId': doc.id
            })
            if len(related_products) >= 4:  # Limit to 4 related products
                break
    
    return render_template('customer/product_details.html',
                         product=product_data,
                         vendor=vendor_data,
                         reviews=reviews_list,
                         related_products=related_products)

@app.route('/place_order', methods=['POST'])
@login_required
def place_order():
    if current_user.role != 'buyer':
        flash('Access denied', 'danger')
        return redirect(url_for('home'))
    
    try:
        # Get form data
        full_name = request.form.get('fullName')
        phone_number = request.form.get('phoneNumber')
        shipping_address = request.form.get('address')
        payment_method = request.form.get('paymentMethod', 'Cash on Delivery')
        
        # Get cart items
        cart_items = list(db.collection('users').document(current_user.id).collection('cart').stream())
        products = []
        total_amount = 0
        vendor_id = None
        
        for item in cart_items:
            item_data = item.to_dict()
            product_doc = db.collection('products').document(item_data['productId']).get()
            if product_doc.exists:
                product_data = product_doc.to_dict()
                item_total = product_data.get('productPrice', 0) * item_data.get('quantity', 1)
                total_amount += item_total
                
                # Get vendor ID from the first product
                if vendor_id is None:
                    vendor_id = product_data.get('vendorId')
                
                products.append({
                    'productId': item_data['productId'],
                    'productName': product_data.get('productName'),
                    'price': product_data.get('productPrice', 0),
                    'quantity': item_data.get('quantity', 1),
                    'size': item_data.get('size'),
                    'imageUrl': product_data.get('imageUrlList', [''])[0],
                    'vendorId': product_data.get('vendorId')
                })
        
        if not vendor_id:
            flash('No valid vendor found for the products', 'danger')
            return redirect(url_for('checkout'))
        
        # Create order document
        order_ref = db.collection('orders').document()
        order_data = {
            'orderId': order_ref.id,
            'buyerId': current_user.id,
            'vendorId': vendor_id,
            'buyerName': full_name,
            'buyerPhone': phone_number,
            'shippingAddress': shipping_address,
            'paymentMethod': payment_method,
            'products': products,
            'totalAmount': total_amount,
            'status': 'pending',
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': firestore.SERVER_TIMESTAMP
        }
        
        # Add order to Firestore
        order_ref.set(order_data)
        
        # Clear cart
        for item in cart_items:
            item.reference.delete()
        
        flash('Order placed successfully!', 'success')
        return redirect(url_for('order_details', order_id=order_ref.id))
        
    except Exception as e:
        flash(f'Error placing order: {str(e)}', 'danger')
        return redirect(url_for('checkout'))

@app.route('/test/create_order')
@login_required
def test_create_order():
    if current_user.role != 'buyer':
        flash('Access denied', 'danger')
        return redirect(url_for('home'))
    
    try:
        # Create a test order
        order_ref = db.collection('orders').document()
        order_data = {
            'orderId': order_ref.id,
            'buyerId': current_user.id,
            'buyerName': 'Test Buyer',
            'buyerPhone': '1234567890',
            'courierId': 'test_courier_id',
            'courierName': 'Test Courier',
            'createdAt': firestore.SERVER_TIMESTAMP,
            'pickedUpAt': firestore.SERVER_TIMESTAMP,
            'paymentMethod': 'Cash on Delivery',
            'shippingAddress': '123 Test Street, Test City, Test State, Test Country',
            'status': 'pending',
            'totalAmount': 100.00,
            'updatedAt': firestore.SERVER_TIMESTAMP,
            'vendorId': 'test_vendor_id',
            'products': [
                {
                    'productId': 'test_product_1',
                    'productName': 'Test Product 1',
                    'price': 50.00,
                    'quantity': 2,
                    'size': 'M',
                    'imageUrl': 'https://example.com/test1.jpg'
                }
            ]
        }
        
        # Add order to Firestore
        order_ref.set(order_data)
        
        flash('Test order created successfully!', 'success')
        return redirect(url_for('orders'))
        
    except Exception as e:
        flash(f'Error creating test order: {str(e)}', 'danger')
        return redirect(url_for('home'))

# Add debug route to view raw order data
@app.route('/debug/order/<order_id>')
@login_required
def debug_order(order_id):
    if current_user.role != 'buyer':
        flash('Access denied', 'danger')
        return redirect(url_for('home'))
    
    try:
        # Get order details
        order_doc = db.collection('orders').document(order_id).get()
        if not order_doc.exists:
            flash('Order not found', 'danger')
            return redirect(url_for('orders'))
        
        order_data = order_doc.to_dict()
        if order_data.get('buyerId') != current_user.id:
            flash('Access denied', 'danger')
            return redirect(url_for('orders'))
        
        # Return raw order data as JSON
        return jsonify({
            'raw_data': order_data,
            'processed_data': {
                'id': str(order_data.get('orderId', '')),
                'buyer_id': str(order_data.get('buyerId', '')),
                'buyer_name': str(order_data.get('buyerName', '')),
                'buyer_phone': str(order_data.get('buyerPhone', '')),
                'courier_id': str(order_data.get('courierId', '')),
                'courier_name': str(order_data.get('courierName', '')),
                'created_at': str(order_data.get('createdAt', '')),
                'picked_up_at': str(order_data.get('pickedUpAt', '')),
                'payment_method': str(order_data.get('paymentMethod', '')),
                'shipping_address': str(order_data.get('shippingAddress', '')),
                'status': str(order_data.get('status', '')),
                'total': float(order_data.get('totalAmount', 0)),
                'updated_at': str(order_data.get('updatedAt', '')),
                'vendor_id': str(order_data.get('vendorId', '')),
                'products': order_data.get('products', [])
            }
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True) 