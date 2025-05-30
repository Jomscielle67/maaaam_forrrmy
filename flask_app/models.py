from datetime import datetime
from firebase_admin import firestore

class Category:
    def __init__(self, id, name, image_url, description):
        self.id = id
        self.name = name
        self.image_url = image_url
        self.description = description

    @classmethod
    def from_dict(cls, data, id=None):
        return cls(
            id=id or data.get('id'),
            name=data.get('name'),
            image_url=data.get('imageUrl'),
            description=data.get('description')
        )

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'imageUrl': self.image_url,
            'description': self.description
        }

class Product:
    def __init__(self, id, name, description, price, category_id, vendor_id, 
                 images, stock, created_at=None, updated_at=None):
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.category_id = category_id
        self.vendor_id = vendor_id
        self.images = images
        self.stock = stock
        self.created_at = created_at or datetime.now()
        self.updated_at = updated_at or datetime.now()

    @classmethod
    def from_dict(cls, data, id=None):
        return cls(
            id=id or data.get('id'),
            name=data.get('name'),
            description=data.get('description'),
            price=data.get('price'),
            category_id=data.get('categoryId'),
            vendor_id=data.get('vendorId'),
            images=data.get('images', []),
            stock=data.get('stock', 0),
            created_at=data.get('createdAt'),
            updated_at=data.get('updatedAt')
        )

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'price': self.price,
            'categoryId': self.category_id,
            'vendorId': self.vendor_id,
            'images': self.images,
            'stock': self.stock,
            'createdAt': self.created_at,
            'updatedAt': self.updated_at
        }

class Order:
    def __init__(self, id, buyer_id, vendor_id, products, total_amount,
                 shipping_address, payment_method, status, created_at=None):
        self.id = id
        self.buyer_id = buyer_id
        self.vendor_id = vendor_id
        self.products = products
        self.total_amount = total_amount
        self.shipping_address = shipping_address
        self.payment_method = payment_method
        self.status = status
        self.created_at = created_at or datetime.now()

    @classmethod
    def from_dict(cls, data, id=None):
        return cls(
            id=id or data.get('id'),
            buyer_id=data.get('buyerId'),
            vendor_id=data.get('vendorId'),
            products=data.get('products', []),
            total_amount=data.get('totalAmount'),
            shipping_address=data.get('shippingAddress'),
            payment_method=data.get('paymentMethod'),
            status=data.get('status'),
            created_at=data.get('createdAt')
        )

    def to_dict(self):
        return {
            'id': self.id,
            'buyerId': self.buyer_id,
            'vendorId': self.vendor_id,
            'products': self.products,
            'totalAmount': self.total_amount,
            'shippingAddress': self.shipping_address,
            'paymentMethod': self.payment_method,
            'status': self.status,
            'createdAt': self.created_at
        }

class Review:
    def __init__(self, id, product_id, user_id, user_name, user_image,
                 rating, comment, created_at, is_verified_purchase=False):
        self.id = id
        self.product_id = product_id
        self.user_id = user_id
        self.user_name = user_name
        self.user_image = user_image
        self.rating = rating
        self.comment = comment
        self.created_at = created_at
        self.is_verified_purchase = is_verified_purchase

    @classmethod
    def from_dict(cls, data, id=None):
        return cls(
            id=id or data.get('id'),
            product_id=data.get('productId'),
            user_id=data.get('userId'),
            user_name=data.get('userName'),
            user_image=data.get('userImage'),
            rating=data.get('rating'),
            comment=data.get('comment'),
            created_at=data.get('createdAt'),
            is_verified_purchase=data.get('isVerifiedPurchase', False)
        )

    def to_dict(self):
        return {
            'id': self.id,
            'productId': self.product_id,
            'userId': self.user_id,
            'userName': self.user_name,
            'userImage': self.user_image,
            'rating': self.rating,
            'comment': self.comment,
            'createdAt': self.created_at,
            'isVerifiedPurchase': self.is_verified_purchase
        } 