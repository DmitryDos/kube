package handler

import (
	"errors"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

type Claims struct {
	UserID interface{} `json:"userId"` // Может быть int или string (UUID)
	jwt.RegisteredClaims
}

func AuthenticateJWT() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			log.Printf("[Auth] No Authorization header")
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header required"})
			c.Abort()
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			log.Printf("[Auth] Invalid authorization header format")
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid authorization header format"})
			c.Abort()
			return
		}

		tokenString := parts[1]
		jwtSecret := os.Getenv("JWT_SECRET")
		if jwtSecret == "" {
			jwtSecret = "your-super-secret-jwt-key-here"
		}

		token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, errors.New("unexpected signing method")
			}
			return []byte(jwtSecret), nil
		})

		if err != nil {
			log.Printf("[Auth] Token parse error: %v", err)
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid or expired token"})
			c.Abort()
			return
		}

		if !token.Valid {
			log.Printf("[Auth] Token is not valid")
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid or expired token"})
			c.Abort()
			return
		}

		claims, ok := token.Claims.(*Claims)
		if !ok {
			log.Printf("[Auth] Invalid token claims type")
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token claims"})
			c.Abort()
			return
		}

		// Логируем что пришло
		log.Printf("[Auth] Token claims UserID type: %T, value: %v", claims.UserID, claims.UserID)

		// Парсим UserID - может быть int, string (UUID) или число как float64 из JSON
		var userIDUUID uuid.UUID
		switch v := claims.UserID.(type) {
		case string:
			// Попытка парсить как UUID
			parsed, err := uuid.Parse(v)
			if err != nil {
				log.Printf("[Auth] Failed to parse UserID as UUID from string '%s': %v", v, err)
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid user ID format"})
				c.Abort()
				return
			}
			userIDUUID = parsed
			log.Printf("[Auth] Successfully parsed UUID: %s", userIDUUID.String())
		case float64:
			// Если это число (старый формат), конвертируем в строку и пробуем найти пользователя
			// Но у нас нет маппинга int -> UUID, поэтому нужно получать UUID из auth-service
			log.Printf("[Auth] UserID is numeric (legacy format): %v", v)
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Legacy token format not supported. Please re-login."})
			c.Abort()
			return
		case int:
			// Аналогично
			log.Printf("[Auth] UserID is int (legacy format): %v", v)
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Legacy token format not supported. Please re-login."})
			c.Abort()
			return
		default:
			log.Printf("[Auth] Unknown UserID type: %T, value: %v", v, v)
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid user ID format"})
			c.Abort()
			return
		}

		log.Printf("[Auth] Authenticated user: %s", userIDUUID.String())
		c.Set("userID", userIDUUID)
		c.Next()
	}
}

