import { Query } from './Query';
import { Mutation } from './Mutation';
import { ProductSubscription, UserSubscription } from './Subscription';
import { SubCategory, Checkin, Company, Product, Category, AuthPayload, User } from './Types';

export const resolvers = {
    Query,
    User,
    Mutation,
    Product,
    Checkin,
    AuthPayload,
    ProductSubscription,
    UserSubscription,
    Category,
    Company,
    SubCategory,
};
