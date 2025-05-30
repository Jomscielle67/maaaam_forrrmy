from datetime import datetime

class Category:
    def __init__(self, id, name, imageUrl, description=None):
        self.id = id
        self.name = name
        self.imageUrl = imageUrl
        self.description = description
        self.created_at = datetime.utcnow()
        self.updated_at = datetime.utcnow()

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'imageUrl': self.imageUrl,
            'description': self.description,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }

    @classmethod
    def from_dict(cls, data):
        category = cls(
            id=data['id'],
            name=data['name'],
            imageUrl=data['imageUrl'],
            description=data.get('description')
        )
        if 'created_at' in data:
            category.created_at = datetime.fromisoformat(data['created_at'])
        if 'updated_at' in data:
            category.updated_at = datetime.fromisoformat(data['updated_at'])
        return category
